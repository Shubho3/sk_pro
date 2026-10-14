import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/invoice.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';
import 'office_actions.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');
final _dateFmt = DateFormat('d MMM yyyy');

Color _invoiceColor(InvoiceStatus s) {
  switch (s) {
    case InvoiceStatus.unpaid:
      return Colors.red;
    case InvoiceStatus.partial:
      return Colors.amber.shade800;
    case InvoiceStatus.paid:
      return Colors.green;
  }
}

/// Company bills: outstanding balance, pay button, invoices and payment history.
class OfficeSubscriptionView extends ConsumerWidget {
  const OfficeSubscriptionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final companyId = user?.companyId;
    if (companyId == null) {
      return const Center(child: Text('No company linked.'));
    }
    final company = ref.watch(companyByIdProvider(companyId)).value;
    final invoicesAsync = ref.watch(companyInvoicesProvider(companyId));
    final paymentsAsync = ref.watch(companyPaymentsProvider(companyId));
    final outstanding = company?.outstanding ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Outstanding balance',
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_currency.format(outstanding),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: outstanding <= 0
                    ? null
                    : () => payBillFlow(
                          context,
                          ref,
                          companyId: companyId,
                          companyName: company?.name ?? '',
                          outstanding: outstanding,
                        ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pay Now'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Invoices',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        invoicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorStateView(message: '$e'),
          data: (invoices) {
            if (invoices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No invoices generated yet.'),
              );
            }
            return Column(
              children: [
                for (final inv in invoices)
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Invoice ${inv.month}'),
                          subtitle: Text(
                              'Total ${_currency.format(inv.subtotal)} \u2022 '
                              'Paid ${_currency.format(inv.paid)}'),
                          trailing: Chip(
                            label: Text(inv.status.name,
                                style: TextStyle(
                                    color: _invoiceColor(inv.status),
                                    fontSize: 12)),
                            backgroundColor: _invoiceColor(inv.status)
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(pdfInvoiceServiceProvider)
                                    .printOrShare(inv),
                                icon: const Icon(
                                    Icons.picture_as_pdf_outlined, size: 18),
                                label: const Text('Download'),
                              ),
                              if (inv.balance > 0) ...[
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => payBillFlow(
                                    context,
                                    ref,
                                    companyId: companyId,
                                    companyName: company?.name ?? '',
                                    outstanding: inv.balance,
                                    invoiceId: inv.id,
                                    invoiceMonth: inv.month,
                                  ),
                                  icon: const Icon(
                                      Icons.payments_outlined, size: 18),
                                  label: const Text('Pay this bill'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Payment history',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        paymentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorStateView(message: '$e'),
          data: (payments) {
            if (payments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No payments recorded yet.'),
              );
            }
            return Column(
              children: [
                for (final p in payments)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(_currency.format(p.amount)),
                    subtitle: Text(
                      '${p.method.name}'
                      '${p.collectedAt != null ? ' \u2022 ${_dateFmt.format(p.collectedAt!)}' : ''}',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
