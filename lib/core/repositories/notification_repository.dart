import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  List<AppNotification> _sortByNewest(Iterable<AppNotification> items) {
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

  Stream<List<AppNotification>> watchForUser(dynamic uid) => _supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('to_uid', _parseId(uid))
      .map((s) => _sortByNewest(s.map((m) => AppNotification.fromMap(m))));

  Stream<List<AppNotification>> watchForRole(String role) => _supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('to_role', role)
      .map((s) => _sortByNewest(s.map((m) => AppNotification.fromMap(m))));

  Future<int> create(AppNotification notification) async {
    final res = await _supabase
        .from('notifications')
        .insert(notification.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> markRead(dynamic id) =>
      _supabase.from('notifications').update({'read': true}).eq('id', _parseId(id));
}
