import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_tea_stall/core/models/complaint.dart';
import 'package:smart_tea_stall/core/providers/auth_providers.dart';
import 'package:smart_tea_stall/core/providers/repository_providers.dart';
import 'package:smart_tea_stall/ui/views/admin/admin_home_view.dart';
import 'package:smart_tea_stall/ui/views/admin/inbox_view.dart';
import 'package:smart_tea_stall/ui/views/admin/inventory_view.dart';
import 'package:smart_tea_stall/ui/views/admin/master_data_view.dart';
import 'package:smart_tea_stall/ui/views/admin/offices_view.dart';
import 'package:smart_tea_stall/ui/views/admin/helpers_view.dart';
import 'package:smart_tea_stall/ui/views/admin/unified_add_dialog.dart';
import 'package:smart_tea_stall/ui/widgets/adaptive_nav_scaffold.dart';

import 'package:smart_tea_stall/ui/widgets/change_password_dialog.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> {
  int _currentIndex = 0;

  void _showAdminSettings(BuildContext context) {
    final user = ref.read(appUserProvider).value;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFF06030)),
            SizedBox(width: 10),
            Text(
              'Admin Settings',
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
                'Admin User ID',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                user.userId,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E2530)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Name',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                user.name.isEmpty ? 'System Administrator' : user.name,
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
              subtitle: const Text('Update admin login password', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
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

  Widget _buildView(int index) {
    switch (index) {
      case 0:
        return const AdminHomeView();
      case 1:
        return const InventoryView();
      case 2:
        return const OfficesView();
      case 3:
        return const HelpersView();
      default:
        return const AdminHomeView();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inbox now lives as an app-bar action rather than a nav destination; its
    // badge counts the same two queues the inbox itself shows (pending item
    // requests + unresolved complaints).
    final pendingRequests =
        ref.watch(pendingRequestsProvider).value?.length ?? 0;
    final openComplaints = ref
            .watch(allComplaintsProvider)
            .value
            ?.where((c) => c.status != ComplaintStatus.resolved)
            .length ??
        0;
    final inboxCount = pendingRequests + openComplaints;

    return AdaptiveNavScaffold(
      title: 'Admin Panel',
      hideBottomBarOnMobile: true,
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      actions: [
        IconButton(
          tooltip: 'Inventory',
          icon: const Icon(Icons.inventory_2_outlined),
          onPressed: () {
            if (MediaQuery.sizeOf(context).width >= 800) {
              setState(() => _currentIndex = 1);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'Inventory',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    body: const InventoryView(),
                  ),
                ),
              );
            }
          },
        ),
        PopupMenuButton<AddTargetType>(
          tooltip: 'Add Company or Employee',
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF06030)),
          onSelected: (type) =>
              UnifiedAddDialog.show(context, initialType: type),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: AddTargetType.company,
              child: Row(
                children: [
                  Icon(Icons.business_rounded,
                      color: Color(0xFFF06030), size: 18),
                  SizedBox(width: 8),
                  Text('Add Company'),
                ],
              ),
            ),
            PopupMenuItem(
              value: AddTargetType.employee,
              child: Row(
                children: [
                  Icon(Icons.delivery_dining_rounded,
                      color: Color(0xFF3B82F6), size: 18),
                  SizedBox(width: 8),
                  Text('Add Employee'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Master Data Settings',
          icon: const Icon(Icons.tune_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MasterDataView()),
          ),
        ),
        IconButton(
          tooltip: 'Inbox',
          icon: Badge(
            isLabelVisible: inboxCount > 0,
            label: Text('$inboxCount'),
            child: const Icon(Icons.inbox_outlined),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminInboxScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Admin Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showAdminSettings(context),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(sessionServiceProvider).clear();
            await ref.read(authServiceProvider).signOut();
          },
        ),
      ],
      body: _buildView(_currentIndex),
      destinations: const [
        AdaptiveDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Dashboard',
        ),
        AdaptiveDestination(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: 'Inventory',
        ),
        AdaptiveDestination(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: 'Companies',
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Employees',
        ),
      ],
    );
  }
}
