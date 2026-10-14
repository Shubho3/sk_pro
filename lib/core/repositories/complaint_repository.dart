import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint.dart';

class ComplaintRepository {
  ComplaintRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<Complaint> _sortByNewest(Iterable<Complaint> items) {
    final byId = <int, Complaint>{};
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

  Stream<List<Complaint>> watchAll() => _supabase
      .from('complaints')
      .stream(primaryKey: ['id'])
      .map((s) => _sortByNewest(s.map((m) => Complaint.fromMap(m))));

  Stream<List<Complaint>> watchByUser(dynamic uid) => _supabase
      .from('complaints')
      .stream(primaryKey: ['id'])
      .eq('raised_by_uid', _parseId(uid))
      .map((s) => _sortByNewest(s.map((m) => Complaint.fromMap(m))));

  Stream<List<Complaint>> watchByCompany(dynamic companyId) => _supabase
      .from('complaints')
      .stream(primaryKey: ['id'])
      .eq('company_id', _parseId(companyId))
      .map((s) => _sortByNewest(s.map((m) => Complaint.fromMap(m))));

  Future<int> create(Complaint complaint) async {
    final res = await _supabase
        .from('complaints')
        .insert(complaint.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> setStatus(dynamic id, ComplaintStatus status) =>
      _supabase.from('complaints').update({'status': status.name}).eq('id', _parseId(id));

  Future<void> delete(dynamic id) =>
      _supabase.from('complaints').delete().eq('id', _parseId(id));
}
