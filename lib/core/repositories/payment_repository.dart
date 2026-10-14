import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment.dart';

class PaymentRepository {
  PaymentRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<Payment> _sortByNewest(Iterable<Payment> items) {
    final byId = <int, Payment>{};
    for (final it in items) {
      byId[it.id] = it;
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final ad = a.collectedAt;
        final bd = b.collectedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return -1;
        if (bd == null) return 1;
        return bd.compareTo(ad);
      });
    return list;
  }

  Stream<List<Payment>> watchAll() => _supabase
      .from('payments')
      .stream(primaryKey: ['id'])
      .map((s) => _sortByNewest(s.map((m) => Payment.fromMap(m))));

  Stream<List<Payment>> watchByCompany(dynamic companyId) => _supabase
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('company_id', _parseId(companyId))
      .map((s) => _sortByNewest(s.map((m) => Payment.fromMap(m))));

  Stream<List<Payment>> watchByEmployee(dynamic employeeId) => _supabase
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('employee_id', _parseId(employeeId))
      .map((s) => _sortByNewest(s.map((m) => Payment.fromMap(m))));

  Future<int> record(Payment payment) async {
    final res = await _supabase
        .from('payments')
        .insert(payment.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<List<Payment>> getByInvoice(dynamic invoiceId) async {
    final res = await _supabase
        .from('payments')
        .select()
        .eq('invoice_id', _parseId(invoiceId));
    return _sortByNewest(
        (res as List).map((m) => Payment.fromMap(m as Map<String, dynamic>)));
  }

  Future<List<Payment>> getByCompany(dynamic companyId) async {
    final res = await _supabase
        .from('payments')
        .select()
        .eq('company_id', _parseId(companyId));
    return _sortByNewest(
        (res as List).map((m) => Payment.fromMap(m as Map<String, dynamic>)));
  }
}
