import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/company.dart';
import '../../../core/models/invoice.dart';
import '../../../core/models/item_request.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/payment_request.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/shimmer_loading.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

/// Admin screen for viewing, auditing, and managing customer monthly bills.
/// Features customer selection dropdown, current & last month outstanding summaries,
/// automatic bill pre-generation, paid vs unpaid tabs, PDF export, and payment requests.
class CustomerBillScreen extends ConsumerStatefulWidget {
  const CustomerBillScreen({
    super.key,
    this.initialCompanyId,
    this.showAppBar,
  });

  final dynamic initialCompanyId;
  final bool? showAppBar;

  @override
  ConsumerState<CustomerBillScreen> createState() => _CustomerBillScreenState();
}

class _CustomerBillScreenState extends ConsumerState<CustomerBillScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  dynamic _selectedCompanyId;
  String? _selectedMonthFilter;
  bool _isGeneratingBill = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCompanyId = widget.initialCompanyId;
    _selectedMonthFilter = DateFormat('yyyy-MM').format(DateTime.now());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(approvedCompaniesProvider);

    final showBar = widget.showAppBar ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: showBar
          ? AppBar(
              title: const Text(
                'Customer Billing',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: const Color(0xFFE2E8F0), height: 1),
              ),
            )
          : null,
      body: companiesAsync.when(
        loading: () => const ShimmerList(itemCount: 4),
        error: (e, _) => Center(child: Text('Error loading companies: $e')),
        data: (companies) {
          if (companies.isEmpty) {
            return const Center(
              child: Text(
                'No approved corporate clients found.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

          // Default to first company if none selected or invalid
          final currentCompany = companies.firstWhere(
            (c) => c.id == _selectedCompanyId,
            orElse: () => companies.first,
          );
          final activeCompanyId = currentCompany.id;

          final invoicesAsync = ref.watch(companyInvoicesProvider(activeCompanyId));
          final paymentsAsync = ref.watch(companyPaymentsProvider(activeCompanyId));
          final requestsAsync = ref.watch(companyRequestsProvider(activeCompanyId));

          return Column(
            children: [
              // 1. Customer Selection Dropdown Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.business_rounded, color: Color(0xFFF06030), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: activeCompanyId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1E2530),
                          ),
                          items: companies.map((c) {
                            return DropdownMenuItem<int>(
                              value: c.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.outstanding > 0
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      _currency.format(c.outstanding),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: c.outstanding > 0
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              setState(() {
                                _selectedCompanyId = newId;
                                _selectedMonthFilter =
                                    DateFormat('yyyy-MM').format(DateTime.now());
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 2. Invoices & Outstanding Content
              Expanded(
                child: invoicesAsync.when(
                  loading: () => const ShimmerList(itemCount: 3),
                  error: (e, _) => Center(child: Text('Error loading invoices: $e')),
                  data: (invoices) {
                    final payments = paymentsAsync.value ?? [];
                    final requests = requestsAsync.value ?? [];

                    // Calculate current month and last month outstanding
                    final now = DateTime.now();
                    final currentMonthKey = DateFormat('yyyy-MM').format(now);
                    final lastMonthDate = DateTime(now.year, now.month - 1);
                    final lastMonthKey = DateFormat('yyyy-MM').format(lastMonthDate);

                    Invoice? currentMonthInvoice;
                    Invoice? lastMonthInvoice;

                    for (final inv in invoices) {
                      if (inv.month == currentMonthKey) {
                        currentMonthInvoice = inv;
                      } else if (inv.month == lastMonthKey) {
                        lastMonthInvoice = inv;
                      }
                    }

                    // Fulfilled addToBill requests for current month (current subscription orders)
                    final curReqs = requests.where((r) =>
                        r.paymentMode == PaymentMode.addToBill &&
                        r.status == RequestStatus.fulfilled &&
                        r.createdAt != null &&
                        DateFormat('yyyy-MM').format(r.createdAt!) == currentMonthKey).toList();
                    final curReqsTotal = curReqs.fold<double>(0, (sum, r) => sum + r.total);

                    final unbilledDelta = currentMonthInvoice != null
                        ? (curReqsTotal > currentMonthInvoice.subtotal
                            ? curReqsTotal - currentMonthInvoice.subtotal
                            : 0.0)
                        : curReqsTotal;

                    final double currentMonthOutstanding = (currentMonthInvoice != null)
                        ? (currentMonthInvoice.balance + unbilledDelta)
                        : curReqsTotal;

                    double lastMonthOutstanding = 0;
                    if (lastMonthInvoice != null) {
                      lastMonthOutstanding = lastMonthInvoice.balance;
                    } else {
                      final lastReqs = requests.where((r) =>
                          r.paymentMode == PaymentMode.addToBill &&
                          r.status == RequestStatus.fulfilled &&
                          r.createdAt != null &&
                          DateFormat('yyyy-MM').format(r.createdAt!) == lastMonthKey);
                      lastMonthOutstanding = lastReqs.fold<double>(0, (sum, r) => sum + r.total);
                    }

                    // Available month keys for filtering
                    final allMonths = invoices.map((i) => i.month).toSet().toList()
                      ..sort((a, b) => b.compareTo(a));

                    // Filtered invoices
                    final filteredInvoices = _selectedMonthFilter == null
                        ? invoices
                        : invoices.where((i) => i.month == _selectedMonthFilter).toList();

                    final unpaidInvoices = filteredInvoices
                        .where((i) => i.status != InvoiceStatus.paid && i.balance > 0)
                        .toList();

                    final paidInvoices = filteredInvoices
                        .where((i) => i.status == InvoiceStatus.paid || i.balance <= 0)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Outstanding Summary Cards (Current month subscription & Last month)
                        _OutstandingCards(
                          currentMonthKey: currentMonthKey,
                          lastMonthKey: lastMonthKey,
                          currentMonthOutstanding: currentMonthOutstanding,
                          lastMonthOutstanding: lastMonthOutstanding,
                          totalOutstanding: currentCompany.outstanding,
                          currentMonthInvoice: currentMonthInvoice,
                          unbilledRequestsCount: curReqs.length,
                          unbilledRequestsAmount: curReqsTotal,
                          unbilledDelta: unbilledDelta,
                          isGenerating: _isGeneratingBill,
                          onGenerateBill: () async {
                            setState(() => _isGeneratingBill = true);
                            try {
                              await ref.read(invoiceServiceProvider).generateForCompany(
                                company: currentCompany,
                                month: now,
                                createIfEmpty: true,
                              );
                              if (!context.mounted) return;
                              setState(() {
                                _selectedMonthFilter = currentMonthKey;
                                _isGeneratingBill = false;
                              });
                              _tabController.animateTo(0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bill generated for ${_formatMonthDisplay(currentMonthKey)}! Showing in unpaid bills.',
                                  ),
                                  backgroundColor: const Color(0xFF1E2530),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _isGeneratingBill = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error generating bill: $e')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date / Month Selector with DatePicker option
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: Color(0xFFF06030),
                                ),
                                label: const Text(
                                  'Select Date',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFFF06030),
                                  ),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFF06030),
                                  width: 1.2,
                                ),
                                backgroundColor:
                                    const Color(0xFFF06030).withValues(alpha: 0.08),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    final monthKey =
                                        DateFormat('yyyy-MM').format(picked);
                                    try {
                                      await ref
                                          .read(invoiceServiceProvider)
                                          .generateForCompany(
                                            company: currentCompany,
                                            month: picked,
                                          );
                                    } catch (_) {}
                                    if (mounted) {
                                      setState(
                                          () => _selectedMonthFilter = monthKey);
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('All Months'),
                                selected: _selectedMonthFilter == null,
                                onSelected: (_) =>
                                    setState(() => _selectedMonthFilter = null),
                              ),
                              const SizedBox(width: 8),
                              for (final m in allMonths) ...[
                                FilterChip(
                                  label: Text(_formatMonthDisplay(m)),
                                  selected: _selectedMonthFilter == m,
                                  onSelected: (_) =>
                                      setState(() => _selectedMonthFilter = m),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (_selectedMonthFilter != null &&
                                  !allMonths.contains(_selectedMonthFilter)) ...[
                                FilterChip(
                                  label: Text(
                                      _formatMonthDisplay(_selectedMonthFilter!)),
                                  selected: true,
                                  onSelected: (_) {},
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Paid vs Unpaid Tabs (sleek, modern rectangular segmented design)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            labelColor: const Color(0xFF0F172A),
                            unselectedLabelColor: const Color(0xFF64748B),
                            labelStyle: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            tabs: [
                              Tab(
                                height: 38,
                                text: 'Unpaid (${unpaidInvoices.length})',
                              ),
                              Tab(
                                height: 38,
                                text: 'Paid (${paidInvoices.length})',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Contents
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            final showUnpaid = _tabController.index == 0;
                            final list = showUnpaid ? unpaidInvoices : paidInvoices;

                            if (list.isEmpty) {
                              final monthLabel = _selectedMonthFilter != null
                                  ? _formatMonthDisplay(_selectedMonthFilter!)
                                  : 'this period';
                              return Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(
                                      showUnpaid
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.receipt_long_outlined,
                                      size: 48,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      showUnpaid
                                          ? 'No unpaid invoices found for $monthLabel.'
                                          : 'No paid invoices found for $monthLabel.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: list.map((invoice) {
                                return _InvoiceCard(
                                  key: ValueKey(invoice.id),
                                  invoice: invoice,
                                  company: currentCompany,
                                  payments: payments
                                      .where((p) => p.invoiceId == invoice.id)
                                      .toList(),
                                  isPaidTab: !showUnpaid,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
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

  String _formatMonthDisplay(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMMM yyyy').format(d);
      }
    } catch (_) {}
    return monthKey;
  }
}

class _OutstandingCards extends StatelessWidget {
  const _OutstandingCards({
    required this.currentMonthKey,
    required this.lastMonthKey,
    required this.currentMonthOutstanding,
    required this.lastMonthOutstanding,
    required this.totalOutstanding,
    this.currentMonthInvoice,
    this.unbilledRequestsCount = 0,
    this.unbilledRequestsAmount = 0,
    this.unbilledDelta = 0,
    this.onGenerateBill,
    this.isGenerating = false,
  });

  final String currentMonthKey;
  final String lastMonthKey;
  final double currentMonthOutstanding;
  final double lastMonthOutstanding;
  final double totalOutstanding;
  final Invoice? currentMonthInvoice;
  final int unbilledRequestsCount;
  final double unbilledRequestsAmount;
  final double unbilledDelta;
  final VoidCallback? onGenerateBill;
  final bool isGenerating;

  String _monthName(String key) {
    try {
      final parts = key.split('-');
      if (parts.length == 2) {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMM yyyy').format(d);
      }
    } catch (_) {}
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OUTSTANDING SUMMARY',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              if (currentMonthInvoice != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'BILL ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Current Month Outstanding
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthName(currentMonthKey)} (Current)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency.format(currentMonthOutstanding),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: currentMonthOutstanding > 0
                              ? const Color(0xFFF06030)
                              : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (currentMonthInvoice != null) ...[
                        Text(
                          unbilledDelta > 0
                              ? 'Bill: ${_currency.format(currentMonthInvoice!.balance)} + ${_currency.format(unbilledDelta)} new'
                              : 'Bill Balance: ${_currency.format(currentMonthInvoice!.balance)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ] else ...[
                        Text(
                          unbilledRequestsCount > 0
                              ? '$unbilledRequestsCount unbilled order(s)'
                              : 'No unbilled orders',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Last Month Outstanding
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthName(lastMonthKey)} (Last)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency.format(lastMonthOutstanding),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: lastMonthOutstanding > 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (onGenerateBill != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isGenerating ? null : onGenerateBill,
                icon: isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.receipt_long_rounded, size: 16),
                label: Text(
                  currentMonthInvoice != null
                      ? 'Re-generate Bill (${_monthName(currentMonthKey)})'
                      : 'Generate Bill (${_monthName(currentMonthKey)})',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF06030),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Company Account Outstanding:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Text(
                _currency.format(totalOutstanding),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2530),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends ConsumerStatefulWidget {
  const _InvoiceCard({
    super.key,
    required this.invoice,
    required this.company,
    required this.payments,
    required this.isPaidTab,
  });

  final Invoice invoice;
  final Company company;
  final List<Payment> payments;
  final bool isPaidTab;

  @override
  ConsumerState<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends ConsumerState<_InvoiceCard> {
  bool _expanded = false;
  bool _requestingPay = false;

  String _formatMonth(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMMM yyyy').format(d);
      }
    } catch (_) {}
    return monthKey;
  }

  Future<void> _recordDirectPayment(BuildContext context) async {
    final controller =
        TextEditingController(text: widget.invoice.balance.toStringAsFixed(0));
    PaymentMethod method = PaymentMethod.cash;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Record Payment: ${widget.company.name}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Received',
                  prefixText: '\u20b9 ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(value: PaymentMethod.cash, label: Text('Cash')),
                  ButtonSegment(value: PaymentMethod.upi, label: Text('UPI')),
                ],
                selected: {method},
                onSelectionChanged: (s) => setDlgState(() => method = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF06030),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final amount = double.tryParse(controller.text.trim()) ?? 0;
      if (amount > 0) {
        await ref.read(distributionServiceProvider).collectPayment(
              companyId: widget.company.id,
              companyName: widget.company.name,
              employeeId: 'admin',
              amount: amount,
              method: method,
              invoiceId: widget.invoice.id,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recorded payment of ${_currency.format(amount)}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final isSettled = inv.status == InvoiceStatus.paid || inv.balance <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSettled
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMonth(inv.month),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1E2530),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inv.lines.length} billed items',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSettled
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFF06030).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSettled ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 13,
                        color: isSettled ? const Color(0xFF10B981) : const Color(0xFFF06030),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSettled ? 'SETTLED' : 'DUE: ${_currency.format(inv.balance)}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSettled ? const Color(0xFF10B981) : const Color(0xFFF06030),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total & Settlement Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                      Text(
                        _currency.format(inv.subtotal),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1E2530),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paid so far:', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                      Text(
                        _currency.format(inv.paid),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  // If Paid: Show Confirmation and How It Was Paid
                  if (widget.payments.isNotEmpty) ...[
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    for (final p in widget.payments)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.payment_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Paid ${_currency.format(p.amount)} via ${p.method.name.toUpperCase()}'
                                '${p.collectedAt != null ? ' on ${DateFormat('d MMM yyyy, h:mm a').format(p.collectedAt!)}' : ''}'
                                '${p.transactionRef != null ? ' (Ref: ${p.transactionRef})' : ''}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else if (isSettled && inv.subtotal > 0) ...[
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Paid ${_currency.format(inv.paid > 0 ? inv.paid : inv.subtotal)} (Account Settled in Full)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Line Items Dropdown
          if (inv.lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? 'Hide item breakdown' : 'View item breakdown',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: inv.lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${line.description}  x  ${line.qty}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                          ),
                        ),
                        Text(
                          _currency.format(line.total),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2530),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Action Buttons Bar
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Delete bill option
                IconButton(
                  tooltip: 'Delete / Clear Bill',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Delete Bill?'),
                        content: Text(
                          'Are you sure you want to remove the bill for ${_formatMonth(inv.month)}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(invoiceRepositoryProvider).delete(inv.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed bill for ${_formatMonth(inv.month)}')),
                        );
                      }
                    }
                  },
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Get PDF Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Get PDF', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(pdfInvoiceServiceProvider).printOrShare(inv);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to export PDF: $e')),
                            );
                          }
                        }
                      },
                    ),
                    if (!isSettled) ...[
                      // Request Customer to get Paid Button
                      FilledButton.icon(
                        icon: _requestingPay
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Request to Pay', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF06030),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _requestingPay
                            ? null
                            : () async {
                                setState(() => _requestingPay = true);
                                try {
                                  final upiConfig =
                                      await ref.read(masterDataRepositoryProvider).getUpiConfig();
                                  final req = PaymentRequest(
                                    id: 0,
                                    companyId: widget.company.id,
                                    companyName: widget.company.name,
                                    invoiceId: inv.id,
                                    month: inv.month,
                                    amount: inv.balance,
                                    upiId: upiConfig.upiId,
                                    payeeName: upiConfig.payeeName,
                                    note: 'Payment request for ${inv.month} bill',
                                  );
                                  await ref.read(paymentRequestRepositoryProvider).create(req);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Payment request sent to ${widget.company.name} for ${_currency.format(inv.balance)}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error sending request: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _requestingPay = false);
                                }
                              },
                      ),
                      // Direct Collect Payment Option
                      IconButton(
                        tooltip: 'Record Direct Payment',
                        icon: const Icon(Icons.add_card_rounded, size: 18, color: Color(0xFF475569)),
                        onPressed: () => _recordDirectPayment(context),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
