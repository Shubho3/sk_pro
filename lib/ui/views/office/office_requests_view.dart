import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/item_request.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';
import 'office_actions.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');
final _dateFmt = DateFormat('d MMM, h:mm a');

Color _requestColor(RequestStatus s) {
  switch (s) {
    case RequestStatus.pending:
      return Colors.orange;
    case RequestStatus.approved:
      return Colors.blue;
    case RequestStatus.fulfilled:
      return Colors.green;
    case RequestStatus.rejected:
      return Colors.red;
  }
}

/// Company requests: list of raised requests + button to raise a new one.
class OfficeRequestsView extends ConsumerWidget {
  const OfficeRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final companyId = user?.companyId;
    if (companyId == null) {
      return const Center(child: Text('No company linked.'));
    }
    final requestsAsync = ref.watch(companyRequestsProvider(companyId));
    final company = ref.watch(companyByIdProvider(companyId)).value;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => raiseCompanyRequestFlow(
          context,
          ref,
          companyId: companyId,
          companyName: company?.name ?? '',
        ),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Raise Request'),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'No requests yet.\nTap "Raise Request" to order items.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              final color = _requestColor(r.status);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: Icon(Icons.receipt_long, color: color),
                  title: Text(
                    '${r.items.length} item(s) \u2022 ${_currency.format(r.total)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${r.paymentMode == PaymentMode.payNow ? 'Pay on delivery' : 'Add to bill'}'
                    '${r.createdAt != null ? ' \u2022 ${_dateFmt.format(r.createdAt!)}' : ''}',
                  ),
                  trailing: Chip(
                    label: Text(r.status.name,
                        style: TextStyle(color: color, fontSize: 12)),
                    backgroundColor: color.withValues(alpha: 0.12),
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                  ),
                  children: [
                    for (final item in r.items)
                      ListTile(
                        dense: true,
                        title: Text(item.name),
                        trailing: Text(
                            '${item.qty} x ${_currency.format(item.price)}'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
