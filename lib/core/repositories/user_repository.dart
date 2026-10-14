import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._supabase);

  final SupabaseClient _supabase;

  Stream<List<AppUser>> watchByRole(UserRole role) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('role', role.name)
        .map((list) {
      final byId = <dynamic, AppUser>{};
      for (final m in list) {
        final u = AppUser.fromMap(m);
        byId[u.id] = u;
      }
      final users = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users;
    });
  }

  Stream<List<AppUser>> watchEmployees() => watchByRole(UserRole.employee);

  Future<AppUser?> getById(dynamic idOrUid) async {
    final query = _supabase.from('users').select();
    final res = idOrUid is int
        ? await query.eq('id', idOrUid).maybeSingle()
        : await query.eq('auth_id', idOrUid.toString()).maybeSingle();
    return res != null ? AppUser.fromMap(res) : null;
  }

  Future<void> setStatus(dynamic idOrUid, UserStatus status) async {
    final query = _supabase.from('users').update({'status': status.name});
    if (idOrUid is int) {
      await query.eq('id', idOrUid);
    } else {
      await query.eq('auth_id', idOrUid.toString());
    }
  }

  Future<void> update(dynamic idOrUid, Map<String, dynamic> data) async {
    final query = _supabase.from('users').update(data);
    if (idOrUid is int) {
      await query.eq('id', idOrUid);
    } else {
      await query.eq('auth_id', idOrUid.toString());
    }
  }

  Future<bool> isUserIdTaken(String userId) async {
    final cleanId = userId.trim().toLowerCase();
    final res = await _supabase
        .from('users')
        .select('id')
        .eq('user_id', cleanId)
        .limit(1);
    return res.isNotEmpty;
  }

  Future<AppUser?> getByUserId(String userId) async {
    final cleanId = userId.trim().toLowerCase();
    final res = await _supabase
        .from('users')
        .select()
        .eq('user_id', cleanId)
        .maybeSingle();
    return res != null ? AppUser.fromMap(res) : null;
  }
}
