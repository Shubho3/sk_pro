import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/master_data.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/status_views.dart';
import 'master_data_view.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

class InventoryView extends ConsumerWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_inventory_master_data',
            tooltip: 'Master Data Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MasterDataView()),
            ),
            child: const Icon(Icons.tune),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'fab_add_product',
            onPressed: () => _openProductDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const ShimmerList(itemCount: 6),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No products yet.\nTap "Add Product" to create one.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final lowStock = product.stock <= 10;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2530), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: lowStock
                        ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.12),
                    width: lowStock ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF06030).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF06030).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(
                          Icons.local_cafe_rounded,
                          color: Color(0xFFF06030),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: lowStock
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                                        : const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${product.stock} ${product.unit}${lowStock ? ' (Low Stock)' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: lowStock ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _currency.format(product.price),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                tooltip: 'Edit product',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _openProductDialog(context, ref, product: product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                tooltip: 'Delete product',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _confirmDelete(context, ref, product),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(productRepositoryProvider).delete(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} deleted')),
        );
      }
    }
  }

  Future<void> _openProductDialog(BuildContext context, WidgetRef ref,
      {Product? product}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ProductDialog(product: product),
    );
  }
}

class _ProductDialog extends ConsumerStatefulWidget {
  const _ProductDialog({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  String? _category;
  String? _unit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _category = p?.category;
    _unit = p?.unit;
    _price = TextEditingController(text: p != null ? '${p.price}' : '');
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '');
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    final product = Product(
      id: widget.product?.id ?? 0,
      name: _name.text.trim(),
      category: (_category == null || _category!.trim().isEmpty)
          ? 'Chai & Tea'
          : _category!.trim(),
      unit: (_unit == null || _unit!.trim().isEmpty) ? 'cup' : _unit!.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
    );
    try {
      if (widget.product == null) {
        await repo.add(product);
      } else {
        await repo.update(product);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final categories =
        ref.watch(masterCategoriesProvider).value ?? MasterCategory.defaults;
    final units =
        ref.watch(masterUnitsProvider).value ?? MasterUnit.defaults;

    final categoryNames = categories.map((c) => c.name).toSet();
    if (_category != null && _category!.trim().isNotEmpty) {
      categoryNames.add(_category!.trim());
    } else if (categories.isNotEmpty) {
      _category = categories.first.name;
    }

    final unitItems = <String, String>{};
    for (final u in units) {
      unitItems[u.symbol] = '${u.name} (${u.symbol})';
    }
    if (_unit != null && _unit!.trim().isNotEmpty) {
      unitItems.putIfAbsent(_unit!.trim(), () => _unit!.trim());
    } else if (units.isNotEmpty) {
      _unit = units.first.symbol;
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_name, 'Product Name', required: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categoryNames
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select a category' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit of Measure',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  items: unitItems.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _unit = val),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select a unit' : null,
                ),
              ),
              _field(
                _price,
                'Price',
                keyboard: TextInputType.number,
                validator: _numberValidator,
                prefixText: '\u20b9 ',
              ),
              _field(
                _stock,
                'Stock',
                keyboard: TextInputType.number,
                validator: _numberValidator,
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  const Text('Quick stock: ',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  for (final step in [10, 25, 50, 100])
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('+$step', style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        final cur = int.tryParse(_stock.text.trim()) ?? 0;
                        setState(() => _stock.text = '${cur + step}');
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  String? _numberValidator(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Required';
    if (double.tryParse(v!.trim()) == null) return 'Enter a number';
    return null;
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: const OutlineInputBorder(),
        ),
        validator: validator ??
            (required
                ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
                : null),
      ),
    );
  }
}
