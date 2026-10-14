import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invoice.dart';

class InvoiceRepository {
  InvoiceRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<Invoice> _sortByNewest(Iterable<Invoice> items) {
    final byId = <int, Invoice>{};
    for (final it in items) {
      byId[it.id] = it;
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final ad = a.generatedAt;
        final bd = b.generatedAt;
        if (ad == null && bd == null) return b.month.compareTo(a.month);
        if (ad == null) return -1;
        if (bd == null) return 1;
        return bd.compareTo(ad);
      });
    return list;
  }

  Stream<List<Invoice>> watchAll() => _supabase
      .from('invoices')
      .stream(primaryKey: ['id'])
      .map((s) => _sortByNewest(s.map((m) => Invoice.fromMap(m))));

  Stream<List<Invoice>> watchByCompany(dynamic companyId) => _supabase
      .from('invoices')
      .stream(primaryKey: ['id'])
      .eq('company_id', _parseId(companyId))
      .map((s) => _sortByNewest(s.map((m) => Invoice.fromMap(m))));

  Future<List<Invoice>> getByCompany(dynamic companyId) async {
    final res = await _supabase
        .from('invoices')
        .select()
        .eq('company_id', _parseId(companyId));
    return _sortByNewest(
        (res as List).map((m) => Invoice.fromMap(m as Map<String, dynamic>)));
  }

  Future<int> create(Invoice invoice) async {
    final map = invoice.toMap();
    map['lines'] = invoice.lines.map((l) => l.toMap()).toList();
    final res = await _supabase
        .from('invoices')
        .insert(map)
        .select('id')
        .single();
    final invId = _parseId(res['id']);

    if (invoice.lines.isNotEmpty) {
      final linesData = invoice.lines
          .map((line) => {
                'invoice_id': invId,
                'description': line.description,
                'qty': line.qty,
                'unit_price': line.unitPrice,
                'total': line.total,
              })
          .toList();
      try {
        await _supabase.from('invoice_lines').insert(linesData);
      } catch (_) {}
    }

    return invId;
  }

  Future<Invoice?> getById(dynamic id) async {
    final res = await _supabase
        .from('invoices')
        .select()
        .eq('id', _parseId(id))
        .maybeSingle();
    return res != null ? Invoice.fromMap(res) : null;
  }

  Future<Invoice?> findByCompanyMonth(dynamic companyId, String month) async {
    final res = await _supabase
        .from('invoices')
        .select()
        .eq('company_id', _parseId(companyId))
        .eq('month', month)
        .limit(1)
        .maybeSingle();
    return res != null ? Invoice.fromMap(res) : null;
  }

  Future<void> updateLines(
    dynamic id, {
    required List<InvoiceLine> lines,
    required double paid,
    required InvoiceStatus status,
  }) async {
    final invId = _parseId(id);
    final subtotal = lines.fold<double>(0, (acc, l) => acc + l.total);
    final linesJson = lines.map((l) => l.toMap()).toList();

    await _supabase.from('invoices').update({
      'lines': linesJson,
      'subtotal': subtotal,
      'paid': paid,
      'balance': subtotal - paid,
      'status': status.name,
    }).eq('id', invId);

    try {
      await _supabase.from('invoice_lines').delete().eq('invoice_id', invId);
      final linesData = lines
          .map((line) => {
                'invoice_id': invId,
                'description': line.description,
                'qty': line.qty,
                'unit_price': line.unitPrice,
                'total': line.total,
              })
          .toList();
      await _supabase.from('invoice_lines').insert(linesData);
    } catch (_) {}
  }

  Future<void> setPaid(dynamic id, double paid, InvoiceStatus status) =>
      _supabase.from('invoices').update({
        'paid': paid,
        'status': status.name,
      }).eq('id', _parseId(id));

  Future<void> applyPayment(
    dynamic id,
    double paid,
    double subtotal,
    InvoiceStatus status,
  ) =>
      _supabase.from('invoices').update({
        'paid': paid,
        'balance': subtotal - paid,
        'status': status.name,
      }).eq('id', _parseId(id));

  Future<void> setDocUrl(dynamic id, String url) =>
      _supabase.from('invoices').update({'doc_url': url}).eq('id', _parseId(id));

  Future<void> delete(dynamic id) =>
      _supabase.from('invoices').delete().eq('id', _parseId(id));
}
