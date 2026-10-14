import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/company.dart';
import '../../../core/models/invoice.dart';
import '../../../core/models/payment.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _monthLabel = DateFormat('MMMM yyyy');
final _monthKey = DateFormat('yyyy-MM');
final _dateFmt = DateFormat('d MMM yyyy');

Color _invoiceColor(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.unpaid:
      return Colors.red;
    case InvoiceStatus.partial:
      return Colors.amber.shade800;
    case InvoiceStatus.paid:
      return Colors.green;
  }
}

/// Per-company billing detail, pushed as a full-screen route from the Companies
/// list. Shows the company's details, generates this month's bill, and lists its
/// invoices (with PDF download + record payment) and payment history.
class CompanyDetailView extends ConsumerStatefulWidget {
  const CompanyDetailView({super.key, required this.company});

  final Company company;

  @override
  ConsumerState<CompanyDetailView> createState() => _CompanyDetailViewState();
}

class _CompanyDetailViewState extends ConsumerState<CompanyDetailView> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final invoicesAsync = ref.watch(companyInvoicesProvider(company.id));
    final paymentsAsync = ref.watch(companyPaymentsProvider(company.id));
    final key = _monthKey.format(_month);
    final hasThisMonth =
        (invoicesAsync.value ?? const <Invoice>[]).any((i) => i.month == key);

    return Scaffold(
      appBar: AppBar(title: Text(company.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Details header ------------------------------------------------
          Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.person_outline,
                      value: company.contactPerson),
                  _DetailRow(icon: Icons.phone_outlined, value: company.phone),
                  _DetailRow(
                      icon: Icons.location_on_outlined,
                      value: company.address),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Text('Outstanding',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(_currency.format(company.outstanding),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: company.outstanding > 0
                                    ? Colors.red
                                    : Colors.green,
                              )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- This month's bill ---------------------------------------------
          Text("This month's bill",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _MonthSelector(
            label: _monthLabel.format(_month),
            onPrevious: _busy ? null : () => _shiftMonth(-1),
            // Billing a month that has not happened yet is meaningless.
            onNext: _busy || _isCurrentMonth ? null : () => _shiftMonth(1),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.receipt_long),
            label: Text(hasThisMonth
                ? "Regenerate this month's bill"
                : "Generate this month's bill"),
          ),
          const SizedBox(height: 24),

          // --- Invoices ------------------------------------------------------
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
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'No bills generated yet.',
                );
              }
              return Column(
                children: [
                  for (final inv in invoices) _InvoiceCard(invoice: inv),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // --- Payment history -----------------------------------------------
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
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(_currency.format(p.amount)),
                      subtitle: Text(
                        '${p.method.name}'
                        '${p.collectedAt != null ? ' • ${_dateFmt.format(p.collectedAt!)}' : ''}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(invoiceServiceProvider)
          .generateForCompany(company: widget.company, month: _month);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill generated for ${widget.company.name}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Invoice ${invoice.month}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip(
                  label: Text(invoice.status.name,
                      style: TextStyle(
                          color: _invoiceColor(invoice.status), fontSize: 12)),
                  backgroundColor:
                      _invoiceColor(invoice.status).withValues(alpha: 0.12),
                  side: BorderSide(
                      color: _invoiceColor(invoice.status)
                          .withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in invoice.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${line.description}  x${line.qty}')),
                    Text(_currency.format(line.total)),
                  ],
                ),
              ),
            if (invoice.lines.isEmpty)
              Text('Nothing billable this month.',
                  style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 20),
            _amountRow('Subtotal', invoice.subtotal, bold: true),
            _amountRow('Paid', invoice.paid),
            _amountRow('Balance', invoice.balance,
                bold: true, color: _invoiceColor(invoice.status)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _download(ref),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Download'),
                ),
                if (invoice.balance > 0)
                  TextButton.icon(
                    onPressed: () => _recordPayment(context, ref),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Record payment'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, double value,
      {bool bold = false, Color? color}) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(_currency.format(value),
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color)),
      ],
    );
  }

  Future<void> _download(WidgetRef ref) async {
    await ref.read(pdfInvoiceServiceProvider).printOrShare(invoice);
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref) async {
    final method = await showDialog<PaymentMethod>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record payment'),
        content: Text(
            'Settle the full balance of ${_currency.format(invoice.balance)} '
            'for ${invoice.companyName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, PaymentMethod.upi),
              child: const Text('UPI')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, PaymentMethod.cash),
              child: const Text('Cash')),
        ],
      ),
    );
    if (method == null) return;
    await ref.read(distributionServiceProvider).payByCompany(
          companyId: invoice.companyId,
          companyName: invoice.companyName,
          amount: invoice.balance,
          method: method,
          invoiceId: invoice.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment recorded for ${invoice.companyName}')),
      );
    }
  }
}
