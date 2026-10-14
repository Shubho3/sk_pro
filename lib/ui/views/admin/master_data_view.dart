import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/master_data.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';

/// Admin screen for managing static and dynamic Master Data (Categories & Units)
/// with complete CRUD operations.
class MasterDataView extends ConsumerWidget {
  const MasterDataView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(masterCategoriesProvider);
    final unitsAsync = ref.watch(masterUnitsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Master Data Settings'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.category_outlined),
                text: categoriesAsync.maybeWhen(
                  data: (l) => 'Categories (${l.length})',
                  orElse: () => 'Categories',
                ),
              ),
              Tab(
                icon: const Icon(Icons.straighten_outlined),
                text: unitsAsync.maybeWhen(
                  data: (l) => 'Units (${l.length})',
                  orElse: () => 'Units',
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (val) async {
                if (val == 'seed') {
                  final repo = ref.read(masterDataRepositoryProvider);
                  await repo.seedDefaultCategories();
                  await repo.seedDefaultUnits();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Standard defaults synced')),
                    );
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'seed',
                  child: Row(
                    children: [
                      Icon(Icons.restore, size: 20),
                      SizedBox(width: 8),
                      Text('Sync Default Master Data'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _CategoriesList(asyncData: categoriesAsync),
            _UnitsList(asyncData: unitsAsync),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Categories Tab
// =============================================================================

class _CategoriesList extends ConsumerWidget {
  const _CategoriesList({required this.asyncData});
  final AsyncValue<List<MasterCategory>> asyncData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_category',
        onPressed: () => _openCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              message: 'No categories configured.\nTap "Add Category" to create one.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF06030).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_cafe_outlined,
                        color: Color(0xFFF06030), size: 22),
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1E2530),
                    ),
                  ),
                  subtitle: Text(
                    cat.description.isNotEmpty
                        ? cat.description
                        : 'Order: ${cat.order}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () =>
                            _openCategoryDialog(context, ref, category: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () =>
                            _confirmDeleteCategory(context, ref, cat),
                      ),
                    ],
                  ),
                  onTap: () =>
                      _openCategoryDialog(context, ref, category: cat),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCategoryDialog(BuildContext context, WidgetRef ref,
      {MasterCategory? category}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
  }

  Future<void> _confirmDeleteCategory(
      BuildContext context, WidgetRef ref, MasterCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${category.name}" from Master Data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(masterDataRepositoryProvider)
          .deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${category.name}" removed')),
        );
      }
    }
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.category});
  final MasterCategory? category;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _order;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _desc = TextEditingController(text: c?.description ?? '');
    _order = TextEditingController(text: '${c?.order ?? 0}');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(masterDataRepositoryProvider);
    final name = _name.text.trim();
    final desc = _desc.text.trim();
    final order = int.tryParse(_order.text.trim()) ?? 0;

    try {
      if (widget.category == null) {
        await repo.addCategory(MasterCategory(
          id: 0,
          name: name,
          description: desc,
          order: order,
        ));
      } else {
        await repo.updateCategory(widget.category!.copyWith(
          name: name,
          description: desc,
          order: order,
        ));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter category name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sort),
                ),
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
}

// =============================================================================
// Units Tab
// =============================================================================

class _UnitsList extends ConsumerWidget {
  const _UnitsList({required this.asyncData});
  final AsyncValue<List<MasterUnit>> asyncData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_unit',
        onPressed: () => _openUnitDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (units) {
          if (units.isEmpty) {
            return const EmptyState(
              icon: Icons.straighten_outlined,
              message: 'No units configured.\nTap "Add Unit" to create one.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        unit.symbol.isNotEmpty
                            ? unit.symbol.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    unit.name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1E2530),
                    ),
                  ),
                  subtitle: Text(
                    'Symbol: "${unit.symbol}" \u2022 Order: ${unit.order}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () =>
                            _openUnitDialog(context, ref, unit: unit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () =>
                            _confirmDeleteUnit(context, ref, unit),
                      ),
                    ],
                  ),
                  onTap: () => _openUnitDialog(context, ref, unit: unit),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openUnitDialog(BuildContext context, WidgetRef ref,
      {MasterUnit? unit}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _UnitDialog(unit: unit),
    );
  }

  Future<void> _confirmDeleteUnit(
      BuildContext context, WidgetRef ref, MasterUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text('Delete "${unit.name}" from Master Data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(masterDataRepositoryProvider).deleteUnit(unit.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unit "${unit.name}" removed')),
        );
      }
    }
  }
}

class _UnitDialog extends ConsumerStatefulWidget {
  const _UnitDialog({this.unit});
  final MasterUnit? unit;

  @override
  ConsumerState<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends ConsumerState<_UnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _symbol;
  late final TextEditingController _order;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.unit;
    _name = TextEditingController(text: u?.name ?? '');
    _symbol = TextEditingController(text: u?.symbol ?? '');
    _order = TextEditingController(text: '${u?.order ?? 0}');
  }

  @override
  void dispose() {
    _name.dispose();
    _symbol.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(masterDataRepositoryProvider);
    final name = _name.text.trim();
    final symbol = _symbol.text.trim().isEmpty ? name.toLowerCase() : _symbol.text.trim();
    final order = int.tryParse(_order.text.trim()) ?? 0;

    try {
      if (widget.unit == null) {
        await repo.addUnit(MasterUnit(
          id: 0,
          name: name,
          symbol: symbol,
          order: order,
        ));
      } else {
        await repo.updateUnit(widget.unit!.copyWith(
          name: name,
          symbol: symbol,
          order: order,
        ));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.unit != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Unit' : 'Add Unit'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Unit Name (e.g. Flask 10 cups)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter unit name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbol,
                decoration: const InputDecoration(
                  labelText: 'Symbol / Abbreviation (e.g. flask, cup)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter symbol' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sort),
                ),
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
}
