import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/company.dart';
import '../../../core/models/item_request.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';
import 'item_picker_screen.dart';

/// Employee starts a sale to an approved company: pick the client, then hand
/// over the items. The delivery is always billed (add-to-bill), so the picker
/// opens with the payment choice locked. Opening this screen is itself the
/// check-in — nothing extra is stored.
class CompanySaleScreen extends ConsumerStatefulWidget {
  const CompanySaleScreen({super.key});

  @override
  ConsumerState<CompanySaleScreen> createState() => _CompanySaleScreenState();
}

class _CompanySaleScreenState extends ConsumerState<CompanySaleScreen> {
  String _query = '';

  Future<void> _startSale(Company company) async {
    final result = await Navigator.of(context).push<ItemPickerResult>(
      MaterialPageRoute(
        builder: (_) => ItemPickerScreen(
          title: 'Sale to ${company.name}',
          confirmLabel: 'Do the Sale',
          lockAddToBill: true,
        ),
      ),
    );
    if (result == null || result.items.isEmpty) return;

    final uid = ref.read(appUserProvider).value?.uid;
    if (uid == null) return;

    await ref.read(distributionServiceProvider).distributeGoods(
          companyId: company.id,
          companyName: company.name,
          employeeId: uid,
          items: result.items,
          paymentMode: PaymentMode.addToBill,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sale added to ${company.name}'s subscription")),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(approvedCompaniesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Work')),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (companies) {
          final activeCompanies = companies.where((c) => c.isActive).toList();
          if (activeCompanies.isEmpty) {
            return const EmptyState(
              icon: Icons.business_outlined,
              message: 'No active companies found.',
            );
          }
          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? activeCompanies
              : activeCompanies
                  .where((c) => c.name.toLowerCase().contains(q))
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search companies',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        message: 'No companies match your search.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.storefront_outlined),
                              title: Text(c.name),
                              subtitle:
                                  c.address.isEmpty ? null : Text(c.address),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _startSale(c),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
