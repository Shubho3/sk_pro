import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_tea_stall/core/providers/auth_providers.dart';
import 'package:smart_tea_stall/ui/views/common/notifications_view.dart';
import 'package:smart_tea_stall/ui/views/office/office_home_view.dart';
import 'package:smart_tea_stall/ui/views/office/office_requests_view.dart';
import 'package:smart_tea_stall/ui/views/office/office_subscription_view.dart';
import 'package:smart_tea_stall/ui/views/office/office_complaints_view.dart';
import 'package:smart_tea_stall/ui/widgets/adaptive_nav_scaffold.dart';

import 'payment_request_popup.dart';
import 'package:smart_tea_stall/core/providers/repository_providers.dart';

import 'package:smart_tea_stall/ui/widgets/change_password_dialog.dart';

class OfficeDashboardView extends ConsumerStatefulWidget {
  const OfficeDashboardView({super.key});

  @override
  ConsumerState<OfficeDashboardView> createState() =>
      _OfficeDashboardViewState();
}

class _OfficeDashboardViewState extends ConsumerState<OfficeDashboardView> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const OfficeHomeView(),
    const OfficeRequestsView(),
    const OfficeSubscriptionView(),
    const OfficeComplaintsView(),
  ];

  void _showCompanySettings(BuildContext context) {
    final user = ref.read(appUserProvider).value;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.settings_outlined, color: Color(0xFFF06030)),
            SizedBox(width: 10),
            Text(
              'Company Settings',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              const Text(
                'User ID',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                user.userId,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E2530)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Company Name',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                user.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF06030).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF06030), size: 20),
              ),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Update account login password', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () {
                Navigator.pop(ctx);
                ChangePasswordDialog.show(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final companyId = user?.companyId;
    if (companyId != null) {
      final companyAsync = ref.watch(companyByIdProvider(companyId));
      final pendingRequestsAsync =
          ref.watch(pendingPaymentRequestForCompanyProvider(companyId));
      final pendingRequests = pendingRequestsAsync.value ?? [];
      if (pendingRequests.isNotEmpty) {
        PaymentRequestPopup.checkAndShow(
          context,
          pendingRequests: pendingRequests,
          companyId: companyId,
          companyName: companyAsync.value?.name ?? '',
        );
      }
    }
    return AdaptiveNavScaffold(
      title: 'Company',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Company Settings',
          onPressed: () => _showCompanySettings(context),
        ),
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(sessionServiceProvider).clear();
            await ref.read(authServiceProvider).signOut();
          },
        ),
      ],
      body: _views[_selectedIndex],
      destinations: const [
        AdaptiveDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Home',
        ),
        AdaptiveDestination(
          icon: Icons.add_shopping_cart_outlined,
          selectedIcon: Icons.add_shopping_cart,
          label: 'Requests',
        ),
        AdaptiveDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Bills',
        ),
        AdaptiveDestination(
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: 'Complaints',
        ),
      ],
    );
  }
}
