import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company.dart';

class CompanyRepository {
  CompanyRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<Company> _sorted(Iterable<Company> companies) {
    final byId = <int, Company>{};
    for (final c in companies) {
      byId[c.id] = c;
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Stream<List<Company>> watchAll() => _supabase
      .from('companies')
      .stream(primaryKey: ['id'])
      .map((s) => _sorted(s.map((m) => Company.fromMap(m))));

  Stream<List<Company>> watchByApproval(ApprovalStatus status) => _supabase
      .from('companies')
      .stream(primaryKey: ['id'])
      .eq('approval', status.name)
      .map((s) => _sorted(s.map((m) => Company.fromMap(m))));

  Stream<List<Company>> watchApproved() =>
      watchByApproval(ApprovalStatus.approved);

  Stream<List<Company>> watchPending() =>
      watchByApproval(ApprovalStatus.pending);

  Stream<Company?> watchById(dynamic id) => _supabase
      .from('companies')
      .stream(primaryKey: ['id'])
      .eq('id', _parseId(id))
      .map((d) => d.isEmpty ? null : Company.fromMap(d.first));

  Future<Company?> getById(dynamic id) async {
    final res = await _supabase
        .from('companies')
        .select()
        .eq('id', _parseId(id))
        .maybeSingle();
    return res != null ? Company.fromMap(res) : null;
  }

  Future<int> create(Company company) async {
    final res = await _supabase
        .from('companies')
        .insert(company.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> update(dynamic id, Map<String, dynamic> data) =>
      _supabase.from('companies').update(data).eq('id', _parseId(id));

  Future<void> setApproval(dynamic id, ApprovalStatus status) =>
      _supabase.from('companies').update({'approval': status.name}).eq('id', _parseId(id));

  Future<void> setActive(dynamic id, bool isActive) =>
      _supabase.from('companies').update({'is_active': isActive}).eq('id', _parseId(id));

  Future<void> setOwner(dynamic id, dynamic ownerUid) {
    final ownerId = ownerUid == null ? null : _parseId(ownerUid);
    return _supabase.from('companies').update({'owner_uid': ownerId}).eq('id', _parseId(id));
  }

  /// Adds [delta] to the company's outstanding balance (negative to reduce).
  Future<void> adjustOutstanding(dynamic id, double delta) async {
    await _supabase.rpc(
      'adjust_outstanding',
      params: {
        'p_company_id': _parseId(id),
        'p_delta': delta,
      },
    );
  }
}
