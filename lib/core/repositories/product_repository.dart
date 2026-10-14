import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._supabase);

  final SupabaseClient _supabase;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  Stream<List<Product>> watchAll() => _supabase
      .from('products')
      .stream(primaryKey: ['id'])
      .map((snap) {
        final byId = <int, Product>{};
        for (final m in snap) {
          final p = Product.fromMap(m);
          byId[p.id] = p;
        }
        final list = byId.values.toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Future<int> add(Product product) async {
    final res = await _supabase
        .from('products')
        .insert(product.toMap())
        .select('id')
        .single();
    return _parseId(res['id']);
  }

  Future<void> update(Product product) =>
      _supabase.from('products').update(product.toMap()).eq('id', product.id);

  /// Adds [delta] to stock (use a negative value when goods are distributed).
  Future<void> adjustStock(dynamic id, int delta) async {
    await _supabase.rpc(
      'adjust_stock',
      params: {
        'p_product_id': _parseId(id),
        'p_delta': delta,
      },
    );
  }

  Future<void> delete(dynamic id) =>
      _supabase.from('products').delete().eq('id', _parseId(id));
}
