import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/item_request.dart';
import '../../../core/models/payment_request.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import 'office_actions.dart';
import 'payment_request_popup.dart';
import 'upi_payment_dialog.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

/// Corporate client home:
/// - Subscription amount made for the current month & outstanding balance
/// - Daily deliveries showing who delivered and how much deliveries received
/// - Request stuff (order items) & Pay bill
/// - Automatic payment request dialog from admin with UPI & Barcode flow
class OfficeHomeView extends ConsumerStatefulWidget {
  const OfficeHomeView({super.key});

  @override
  ConsumerState<OfficeHomeView> createState() => _OfficeHomeViewState();
}

class _OfficeHomeViewState extends ConsumerState<OfficeHomeView> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final companyId = user?.companyId;
    if (companyId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No company is linked to this account.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final companyAsync = ref.watch(companyByIdProvider(companyId));
    final company = companyAsync.value;
    final companyName = company?.name ?? '';
    final outstanding = company?.outstanding ?? 0;

    final requestsAsync = ref.watch(companyRequestsProvider(companyId));
    final employeesAsync = ref.watch(employeesProvider);
    final employeesList = employeesAsync.value ?? [];

    final pendingRequestsAsync =
        ref.watch(pendingPaymentRequestForCompanyProvider(companyId));
    final pendingPaymentRequests = pendingRequestsAsync.value ?? [];

    // Trigger popup if there is a pending payment request from admin
    if (pendingPaymentRequests.isNotEmpty) {
      PaymentRequestPopup.checkAndShow(
        context,
        pendingRequests: pendingPaymentRequests,
        companyId: companyId,
        companyName: companyName,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(companyByIdProvider(companyId));
        ref.invalidate(companyRequestsProvider(companyId));
        ref.invalidate(pendingPaymentRequestForCompanyProvider(companyId));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // 1. Header greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName.isEmpty ? 'Corporate Client' : companyName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      color: Color(0xFF1E2530),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF06030).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_cafe, size: 14, color: Color(0xFFF06030)),
                    SizedBox(width: 4),
                    Text(
                      'STATION PORTAL',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF06030),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Active Payment Request Banner (if any)
          if (pendingPaymentRequests.isNotEmpty) ...[
            _PendingPaymentBanner(
              request: pendingPaymentRequests.first,
              companyId: companyId,
              companyName: companyName,
            ),
            const SizedBox(height: 16),
          ],

          // 3. Subscription Status & Amount Card (shows this month's spend & total balance)
          requestsAsync.when(
            loading: () => _HeroBalanceCard(
              outstanding: outstanding,
              monthSubscriptionAmount: 0,
            ),
            error: (_, _) => _HeroBalanceCard(
              outstanding: outstanding,
              monthSubscriptionAmount: 0,
            ),
            data: (allReqs) {
              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month);
              final endOfMonth = DateTime(now.year, now.month + 1);

              final monthReqs = allReqs.where((r) =>
                  r.paymentMode == PaymentMode.addToBill &&
                  r.status == RequestStatus.fulfilled &&
                  r.createdAt != null &&
                  !r.createdAt!.isBefore(startOfMonth) &&
                  r.createdAt!.isBefore(endOfMonth));

              final monthSubscriptionTotal =
                  monthReqs.fold<double>(0, (sum, r) => sum + r.total);

              return _HeroBalanceCard(
                outstanding: outstanding,
                monthSubscriptionAmount: monthSubscriptionTotal,
              );
            },
          ),
          const SizedBox(height: 20),

          // 4. Primary Tactile Pill Action Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => raiseCompanyRequestFlow(
                    context,
                    ref,
                    companyId: companyId,
                    companyName: companyName,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF06030),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF06030).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Request Items',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => payBillFlow(
                    context,
                    ref,
                    companyId: companyId,
                    companyName: companyName,
                    outstanding: outstanding,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_rounded,
                            color: Color(0xFF1E2530), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pay via UPI',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2530),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Daily Deliveries Section ("Customer will show daily deliveries, who is delivering and how much deliveries he is getting daily")
          requestsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error loading deliveries: $e'),
            data: (allReqs) {
              return _DailyDeliveriesCard(
                allRequests: allReqs,
                employees: employeesList,
              );
            },
          ),
          const SizedBox(height: 20),

          // 6. Delivery Schedule Notice Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF475569),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Service Route',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2530),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Morning chai & snacks deliveries run between 9:30 AM – 11:30 AM daily. '
                        'Requests placed are delivered on the employee route stop.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentBanner extends StatelessWidget {
  const _PendingPaymentBanner({
    required this.request,
    required this.companyId,
    required this.companyName,
  });

  final PaymentRequest request;
  final dynamic companyId;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF06030).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF06030).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF06030),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Requested by Admin',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF1E2530),
                  ),
                ),
                Text(
                  'Amount Due: ${_currency.format(request.amount)} (${request.month})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF06030),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF06030),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: () {
              UpiPaymentDialog.show(
                context,
                companyId: companyId,
                companyName: companyName,
                amount: request.amount,
                invoiceId: request.invoiceId,
                invoiceMonth: request.month,
                paymentRequest: request,
              );
            },
            child: const Text('Pay Now', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.outstanding,
    required this.monthSubscriptionAmount,
  });

  final double outstanding;
  final double monthSubscriptionAmount;

  @override
  Widget build(BuildContext context) {
    final owes = outstanding > 0;
    final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2530),
            Color(0xFF131A26),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Month Subscription label & Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${currentMonthName.toUpperCase()} SUBSCRIPTION',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: owes
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: owes
                        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                        : const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  owes ? 'DUES PENDING' : 'ALL SETTLED',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: owes
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFF6EE7B7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two numbers: This month's spend & Total balance
          Row(
            children: [
              // This Month's Spend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Month Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(monthSubscriptionAmount),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 38,
                width: 1,
                color: Colors.white12,
              ),
              const SizedBox(width: 16),
              // Outstanding Balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Outstanding Balance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(outstanding),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: owes ? const Color(0xFFFF8C5A) : const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            owes
                ? 'Added to your monthly corporate subscription bill.'
                : 'All past invoices have been settled in full.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyDeliveriesCard extends StatefulWidget {
  const _DailyDeliveriesCard({
    required this.allRequests,
    required this.employees,
  });

  final List<ItemRequest> allRequests;
  final List<dynamic> employees;

  @override
  State<_DailyDeliveriesCard> createState() => _DailyDeliveriesCardState();
}

class _DailyDeliveriesCardState extends State<_DailyDeliveriesCard> {
  bool _showPastDeliveries = false;

  String _resolveEmployeeName(dynamic employeeId) {
    if (employeeId == null || employeeId.toString().isEmpty) return 'Chai Station Staff';
    try {
      final idStr = employeeId.toString();
      final emp = widget.employees.cast<AppUser?>().firstWhere(
        (e) => e != null && (e.uid == idStr || e.id.toString() == idStr),
        orElse: () => null,
      );
      if (emp != null) {
        return emp.name.isNotEmpty ? emp.name : 'Helper ($employeeId)';
      }
    } catch (_) {}
    return 'Delivery Staff';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final fulfilledRequests = widget.allRequests
        .where((r) => r.status == RequestStatus.fulfilled && r.createdAt != null)
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final todaysDeliveries = fulfilledRequests.where((r) {
      final t = r.createdAt!;
      return !t.isBefore(startOfToday) && !t.isAfter(endOfToday);
    }).toList();

    final pastDeliveries = fulfilledRequests.where((r) {
      final t = r.createdAt!;
      return t.isBefore(startOfToday);
    }).toList();

    final totalItemsToday = todaysDeliveries.fold<int>(
      0,
      (acc, r) => acc + r.items.fold<int>(0, (sum, i) => sum + i.qty),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF06030).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Color(0xFFF06030),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Deliveries',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2530),
                        ),
                      ),
                      Text(
                        'Who delivered and items received today',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: todaysDeliveries.isNotEmpty
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${todaysDeliveries.length} Today ($totalItemsToday pcs)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: todaysDeliveries.isNotEmpty
                        ? const Color(0xFF047857)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Today's deliveries list
          if (todaysDeliveries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF94A3B8)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No deliveries yet today. Your regular route stop is between 9:30 AM – 11:30 AM.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: todaysDeliveries.map((req) {
                final helperName = _resolveEmployeeName(req.employeeId);
                final timeStr = req.createdAt != null
                    ? DateFormat('h:mm a').format(req.createdAt!)
                    : 'Today';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded,
                                  size: 16, color: Color(0xFFF06030)),
                              const SizedBox(width: 6),
                              Text(
                                'Delivered by $helperName',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1E2530),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Line items
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: req.items.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${item.name} x ${item.qty} ${item.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.paymentMode == PaymentMode.addToBill
                                ? 'Added to subscription'
                                : 'Paid at delivery',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _currency.format(req.total),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF1E2530),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          // Past Deliveries Toggle
          if (pastDeliveries.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _showPastDeliveries = !_showPastDeliveries),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _showPastDeliveries
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showPastDeliveries
                          ? 'Hide past deliveries'
                          : 'Show previous deliveries (${pastDeliveries.length})',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showPastDeliveries)
              Column(
                children: pastDeliveries.take(5).map((req) {
                  final helperName = _resolveEmployeeName(req.employeeId);
                  final dateStr = req.createdAt != null
                      ? DateFormat('d MMM, h:mm a').format(req.createdAt!)
                      : 'Past';

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$helperName • $dateStr',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                req.items
                                    .map((i) => '${i.name} (${i.qty})')
                                    .join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _currency.format(req.total),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF1E2530),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}
