import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_user.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/shimmer_loading.dart';
import 'admin_upi_settings_dialog.dart';
import 'customer_bill_screen.dart';
import 'helpers_view.dart';
import 'offices_view.dart';
import 'unified_add_dialog.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

class AdminHomeView extends ConsumerStatefulWidget {
  const AdminHomeView({super.key});

  @override
  ConsumerState<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends ConsumerState<AdminHomeView> {
  int? _selectedCustomerForBill;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final approvedCompanies = ref.watch(approvedCompaniesProvider);
    final pendingCompanies = ref.watch(pendingCompaniesProvider);
    final allRequests = ref.watch(pendingRequestsProvider);
    final upiConfig = ref.watch(adminUpiConfigProvider);
    final employees = ref.watch(employeesProvider);

    // Show smooth, elegant shimmer skeleton if initial data is still loading
    if (products.isLoading && approvedCompanies.isLoading) {
      return const ShimmerDashboard();
    }

    final approvedCount = approvedCompanies.value?.length ?? 0;
    final pendingCount = pendingCompanies.value?.length ?? 0;
    final productList = products.value ?? [];
    final lowStockCount = productList.where((p) => p.stock <= 10).length;
    final employeeList = employees.value ?? [];
    final activeEmployeeCount =
        employeeList.where((e) => e.status == UserStatus.active).length;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 700;
    final isWideCards = screenWidth > 600;

    final companyCard = _ManagementCard(
      title: 'Corporate Clients',
      subtitle:
          '$approvedCount active${pendingCount > 0 ? " • $pendingCount pending" : ""}',
      icon: Icons.business_rounded,
      accentColor: const Color(0xFFF06030),
      onManage: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text(
                'Corporate Clients',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: const OfficesView(),
          ),
        ),
      ),
      onAdd: () => UnifiedAddDialog.show(
        context,
        initialType: AddTargetType.company,
      ),
    );

    final employeeCard = _ManagementCard(
      title: 'Delivery & Employees',
      subtitle:
          '${employeeList.length} staff • $activeEmployeeCount active',
      icon: Icons.delivery_dining_rounded,
      accentColor: const Color(0xFF3B82F6),
      onManage: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text(
                'Delivery & Employees',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: const HelpersView(),
          ),
        ),
      ),
      onAdd: () => UnifiedAddDialog.show(
        context,
        initialType: AddTargetType.employee,
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
          // 1. Header with greeting and UPI Settings Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
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
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Vendor UPI & QR Button
              InkWell(
                onTap: () => AdminUpiSettingsDialog.show(context),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06030).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xFFF06030).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2_rounded,
                          size: 16, color: Color(0xFFF06030)),
                      const SizedBox(width: 6),
                      Text(
                        upiConfig.value?.upiId.isNotEmpty == true
                            ? 'UPI & QR'
                            : 'Setup UPI',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF06030),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quick Refresh Button
              IconButton(
                tooltip: 'Refresh data',
                onPressed: () {
                  ref.invalidate(productsProvider);
                  ref.invalidate(approvedCompaniesProvider);
                  ref.invalidate(pendingCompaniesProvider);
                  ref.invalidate(adminUpiConfigProvider);
                  ref.invalidate(employeesProvider);
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Customer Bill Selector Card (Immediate Dropdown to customer bill)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2530), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06030),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Customer Bill',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Select customer to view monthly outstanding & invoices',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Customer Dropdown
                approvedCompanies.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: ShimmerBox(
                      height: 48,
                      borderRadius: 14,
                      color: Color(0xFF334155),
                    ),
                  ),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  data: (companiesList) {
                    if (companiesList.isEmpty) {
                      return const Text(
                        'No approved clients found.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedCustomerForBill,
                          hint: const Text(
                            'Select Customer for Billing...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.5,
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E2530),
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFFF06030),
                            size: 16,
                          ),
                          items: companiesList.map((c) {
                            return DropdownMenuItem<int>(
                              value: c.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.outstanding > 0
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                          : const Color(0xFF10B981).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      'Due: ${_currency.format(c.outstanding)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: c.outstanding > 0
                                            ? const Color(0xFFFCA5A5)
                                            : const Color(0xFF6EE7B7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _selectedCustomerForBill = val);
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerBillScreen(initialCompanyId: val),
                                ),
                              );
                              if (mounted) {
                                setState(() => _selectedCustomerForBill = null);
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Stat Overview Cards
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Products',
                    value: '${productList.length}',
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFFF06030),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Corporate Clients',
                    value: '$approvedCount',
                    icon: Icons.business_rounded,
                    color: const Color(0xFF3B82F6),
                    subtitle: pendingCount > 0 ? '$pendingCount pending' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Low Stock Alert',
                    value: '$lowStockCount',
                    icon: Icons.warning_amber_rounded,
                    color: lowStockCount > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Requests',
                    value: '${allRequests.value?.length ?? 0}',
                    icon: Icons.inbox_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Products',
                    value: '${productList.length}',
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFFF06030),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Corporate Clients',
                    value: '$approvedCount',
                    icon: Icons.business_rounded,
                    color: const Color(0xFF3B82F6),
                    subtitle: pendingCount > 0 ? '$pendingCount pending' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Low Stock Alert',
                    value: '$lowStockCount',
                    icon: Icons.warning_amber_rounded,
                    color: lowStockCount > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Requests',
                    value: '${allRequests.value?.length ?? 0}',
                    icon: Icons.inbox_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // 4. Sales & Distribution Chart ("some chart at the home only")
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Weekly Distribution & Sales',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF1E2530),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Estimated daily cup/snack dispatch volume',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06030).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'LIVE PULSE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF06030),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // FlChart Bar Chart
                SizedBox(
                  height: 180,
                  child: RepaintBoundary(
                    child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 120,
                      barTouchData: const BarTouchData(
                        enabled: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final index = val.toInt();
                              if (index >= 0 && index < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[index],
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _makeBarGroup(0, 68),
                        _makeBarGroup(1, 85),
                        _makeBarGroup(2, 94),
                        _makeBarGroup(3, 76),
                        _makeBarGroup(4, 110, isHighlight: true),
                        _makeBarGroup(5, 52),
                        _makeBarGroup(6, 25),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
          // 5. Quick Management & Access (Companies & Employees)
          const SizedBox(height: 24),
          const Text(
            'Management & Access',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF1E2530),
            ),
          ),
          const SizedBox(height: 12),
          if (isWideCards)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: companyCard),
                const SizedBox(width: 14),
                Expanded(child: employeeCard),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                companyCard,
                const SizedBox(height: 12),
                employeeCard,
              ],
            ),
          const SizedBox(height: 16),

          // 6. Pending approvals hint if any
          if (pendingCount > 0)
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'Corporate Clients',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    body: const OfficesView(),
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF06030).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF06030).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions_rounded,
                        color: Color(0xFFF06030), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$pendingCount new company registration(s) pending approval. Tap to review.',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E2530),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFF06030), size: 20),
                  ],
                ),
              ),
            ),
        ],
          ),
        ),
      );
  }

  BarChartGroupData _makeBarGroup(int x, double y, {bool isHighlight = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: isHighlight
                ? [const Color(0xFFF06030), const Color(0xFFFF8C5A)]
                : [const Color(0xFF1E2530), const Color(0xFF475569)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 120,
            color: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onManage;
  final VoidCallback onAdd;

  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onManage,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF1E2530),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onManage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2530),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
