import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/master_data.dart';

class MasterDataRepository {
  MasterDataRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  Stream<List<MasterCategory>> watchCategories() {
    return _supabase
        .from('master_categories')
        .stream(primaryKey: ['id'])
        .map((snapshot) {
      if (snapshot.isEmpty) {
        return MasterCategory.defaults;
      }
      final list = snapshot.map((m) => MasterCategory.fromMap(m)).toList();
      list.sort((a, b) {
        final orderComp = a.order.compareTo(b.order);
        if (orderComp != 0) return orderComp;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Future<int> addCategory(MasterCategory category) async {
    final res = await _supabase
        .from('master_categories')
        .insert(category.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> updateCategory(MasterCategory category) =>
      _supabase.from('master_categories').update(category.toMap()).eq('id', category.id);

  Future<void> deleteCategory(dynamic id) =>
      _supabase.from('master_categories').delete().eq('id', _parseId(id));

  Future<void> seedDefaultCategories() async {
    for (final c in MasterCategory.defaults) {
      await _supabase.from('master_categories').upsert(c.toMap());
    }
  }

  // ---------------------------------------------------------------------------
  // Units
  // ---------------------------------------------------------------------------

  Stream<List<MasterUnit>> watchUnits() {
    return _supabase
        .from('master_units')
        .stream(primaryKey: ['id'])
        .map((snapshot) {
      if (snapshot.isEmpty) {
        return MasterUnit.defaults;
      }
      final list = snapshot.map((m) => MasterUnit.fromMap(m)).toList();
      list.sort((a, b) {
        final orderComp = a.order.compareTo(b.order);
        if (orderComp != 0) return orderComp;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Future<int> addUnit(MasterUnit unit) async {
    final res = await _supabase
        .from('master_units')
        .insert(unit.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> updateUnit(MasterUnit unit) =>
      _supabase.from('master_units').update(unit.toMap()).eq('id', unit.id);

  Future<void> deleteUnit(dynamic id) =>
      _supabase.from('master_units').delete().eq('id', _parseId(id));

  Future<void> seedDefaultUnits() async {
    for (final u in MasterUnit.defaults) {
      await _supabase.from('master_units').upsert(u.toMap());
    }
  }

  // ---------------------------------------------------------------------------
  // Admin UPI Settings
  // ---------------------------------------------------------------------------

  Stream<AdminUpiConfig> watchUpiConfig() {
    return _supabase
        .from('app_settings')
        .stream(primaryKey: ['key'])
        .eq('key', 'upi_config')
        .map((list) {
      if (list.isEmpty || list.first['value'] == null) {
        return const AdminUpiConfig();
      }
      final val = list.first['value'];
      if (val is Map) {
        return AdminUpiConfig.fromMap(val.cast<String, dynamic>());
      }
      return const AdminUpiConfig();
    });
  }

  Future<AdminUpiConfig> getUpiConfig() async {
    final res = await _supabase
        .from('app_settings')
        .select()
        .eq('key', 'upi_config')
        .maybeSingle();
    if (res == null || res['value'] == null) {
      return const AdminUpiConfig();
    }
    final val = res['value'];
    if (val is Map) {
      return AdminUpiConfig.fromMap(val.cast<String, dynamic>());
    }
    return const AdminUpiConfig();
  }

  Future<void> saveUpiConfig(AdminUpiConfig config) =>
      _supabase.from('app_settings').upsert({
        'key': 'upi_config',
        'value': config.toMap(),
      });
}
