import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_request.dart';

class PaymentRequestRepository {
  PaymentRequestRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<PaymentRequest> _sortByNewest(Iterable<PaymentRequest> items) {
    final list = items.toList()
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

  Stream<List<PaymentRequest>> watchPendingForCompany(dynamic companyId) {
    return _supabase
        .from('payment_requests')
        .stream(primaryKey: ['id'])
        .eq('company_id', _parseId(companyId))
        .map((s) => _sortByNewest(s
            .map((m) => PaymentRequest.fromMap(m))
            .where((r) => r.status == PaymentRequestStatus.pending)));
  }

  Stream<List<PaymentRequest>> watchByCompany(dynamic companyId) {
    return _supabase
        .from('payment_requests')
        .stream(primaryKey: ['id'])
        .eq('company_id', _parseId(companyId))
        .map((s) => _sortByNewest(s.map((m) => PaymentRequest.fromMap(m))));
  }

  Future<int> create(PaymentRequest request) async {
    final res = await _supabase
        .from('payment_requests')
        .insert(request.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> markPaid(dynamic id, {String? transactionRef}) {
    final data = <String, dynamic>{
      'status': PaymentRequestStatus.paid.name,
      'paid_at': DateTime.now().toIso8601String(),
    };
    if (transactionRef != null) data['transaction_ref'] = transactionRef;
    return _supabase.from('payment_requests').update(data).eq('id', _parseId(id));
  }

  Future<void> markDismissed(dynamic id) {
    return _supabase.from('payment_requests').update({
      'status': PaymentRequestStatus.dismissed.name,
    }).eq('id', _parseId(id));
  }
}
