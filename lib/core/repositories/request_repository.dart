import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item_request.dart';

class RequestRepository {
  RequestRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<ItemRequest> _sortByNewest(Iterable<ItemRequest> items) {
    final byId = <int, ItemRequest>{};
    for (final it in items) {
      byId[it.id] = it;
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return -1;
        if (bd == null) return 1;
        return bd.compareTo(ad);
      });
    return list;
  }

  Stream<List<ItemRequest>> watchAll() => _supabase
      .from('requests')
      .stream(primaryKey: ['id'])
      .map((s) => _sortByNewest(s.map((m) => ItemRequest.fromMap(m))));

  Stream<List<ItemRequest>> watchByCompany(dynamic companyId) => _supabase
      .from('requests')
      .stream(primaryKey: ['id'])
      .eq('company_id', _parseId(companyId))
      .map((s) => _sortByNewest(s.map((m) => ItemRequest.fromMap(m))));

  Stream<List<ItemRequest>> watchByEmployee(dynamic employeeId) => _supabase
      .from('requests')
      .stream(primaryKey: ['id'])
      .eq('employee_id', _parseId(employeeId))
      .map((s) => _sortByNewest(s.map((m) => ItemRequest.fromMap(m))));

  Stream<List<ItemRequest>> watchPending() => _supabase
      .from('requests')
      .stream(primaryKey: ['id'])
      .eq('status', RequestStatus.pending.name)
      .map((s) => _sortByNewest(s.map((m) => ItemRequest.fromMap(m))));

  Future<int> create(ItemRequest request) async {
    final map = request.toMap();
    map['items'] = request.items.map((i) => i.toMap()).toList();
    final res = await _supabase
        .from('requests')
        .insert(map)
        .select('id')
        .single();
    final reqId = _parseId(res['id']);

    if (request.items.isNotEmpty) {
      final linesData = request.items
          .map((line) => {
                'request_id': reqId,
                'product_id': line.productId,
                'name': line.name,
                'qty': line.qty,
                'price': line.price,
                'unit': line.unit,
              })
          .toList();
      try {
        await _supabase.from('request_lines').insert(linesData);
      } catch (_) {}
    }

    return reqId;
  }

  /// One-shot fetch of a company's requests (used for invoice generation).
  Future<List<ItemRequest>> getByCompany(dynamic companyId) async {
    final res = await _supabase
        .from('requests')
        .select()
        .eq('company_id', _parseId(companyId));
    return _sortByNewest(
        (res as List).map((m) => ItemRequest.fromMap(m as Map<String, dynamic>)));
  }

  /// Approved but not yet delivered.
  Stream<List<ItemRequest>> watchApproved() => _supabase
      .from('requests')
      .stream(primaryKey: ['id'])
      .eq('status', RequestStatus.approved.name)
      .map((s) => _sortByNewest(s.map((m) => ItemRequest.fromMap(m))));

  /// A single company's approved requests.
  Stream<List<ItemRequest>> watchApprovedByCompany(dynamic companyId) =>
      _supabase
          .from('requests')
          .stream(primaryKey: ['id'])
          .eq('company_id', _parseId(companyId))
          .map((s) => _sortByNewest(s
              .map((m) => ItemRequest.fromMap(m))
              .where((r) => r.status == RequestStatus.approved)));

  Future<void> setStatus(dynamic id, RequestStatus status) =>
      _supabase.from('requests').update({'status': status.name}).eq('id', _parseId(id));

  Future<void> fulfil(
    dynamic id, {
    required List<RequestLine> items,
    required PaymentMode paymentMode,
    required dynamic employeeId,
  }) async {
    final reqId = _parseId(id);
    final empId = _parseId(employeeId);
    final total = items.fold<double>(0, (acc, i) => acc + i.total);
    final itemsJson = items.map((i) => i.toMap()).toList();

    await _supabase.from('requests').update({
      'items': itemsJson,
      'total': total,
      'payment_mode': paymentMode.name,
      'employee_id': empId,
      'status': RequestStatus.fulfilled.name,
    }).eq('id', reqId);

    // Update request_lines child table
    try {
      await _supabase.from('request_lines').delete().eq('request_id', reqId);
      final linesData = items
          .map((line) => {
                'request_id': reqId,
                'product_id': line.productId,
                'name': line.name,
                'qty': line.qty,
                'price': line.price,
                'unit': line.unit,
              })
          .toList();
      await _supabase.from('request_lines').insert(linesData);
    } catch (_) {}
  }

  Future<void> delete(dynamic id) =>
      _supabase.from('requests').delete().eq('id', _parseId(id));

  /// Requests that are either fulfilled or rejected.
  Stream<List<ItemRequest>> watchProcessed() => _supabase
      .from('requests')
      .stream(primaryKey: ['id'])
      .map((s) => _sortByNewest(
            s
                .map((m) => ItemRequest.fromMap(m))
                .where((r) =>
                    r.status == RequestStatus.fulfilled ||
                    r.status == RequestStatus.rejected),
          ));
}
