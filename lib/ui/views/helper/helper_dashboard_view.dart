import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_tea_stall/core/providers/auth_providers.dart';
import 'package:smart_tea_stall/ui/views/common/notifications_view.dart';
import 'package:smart_tea_stall/ui/views/helper/helper_home_view.dart';
import 'package:smart_tea_stall/ui/views/helper/helper_complaints_view.dart';
import 'package:smart_tea_stall/ui/widgets/adaptive_nav_scaffold.dart';

import 'package:smart_tea_stall/ui/widgets/change_password_dialog.dart';

class HelperDashboardView extends ConsumerStatefulWidget {
  const HelperDashboardView({super.key});

  @override
  ConsumerState<HelperDashboardView> createState() =>
      _HelperDashboardViewState();
}

class _HelperDashboardViewState extends ConsumerState<HelperDashboardView> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const HelperHomeView(),
    const HelperComplaintsView(),
  ];

  void _showEmployeeSettings(BuildContext context) {
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
              'Employee Settings',
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
                'Employee Name',
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
              subtitle: const Text('Update your station sign-in password', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
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
    return AdaptiveNavScaffold(
      title: 'Employee',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Employee Settings',
          onPressed: () => _showEmployeeSettings(context),
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
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: 'Complaints',
        ),
      ],
    );
  }
}
