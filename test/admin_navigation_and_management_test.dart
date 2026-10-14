import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tea_stall/core/models/app_user.dart';
import 'package:smart_tea_stall/core/models/company.dart';
import 'package:smart_tea_stall/core/models/complaint.dart';
import 'package:smart_tea_stall/core/models/item_request.dart';
import 'package:smart_tea_stall/core/models/master_data.dart';
import 'package:smart_tea_stall/core/models/product.dart';
import 'package:smart_tea_stall/core/providers/repository_providers.dart';
import 'package:smart_tea_stall/ui/views/admin/admin_dashboard_view.dart';

void main() {
  const dummyUser = AppUser(
    id: 1,
    authId: 'emp_1',
    userId: 'emp_1',
    name: 'Helper Bob',
    email: 'bob@tea.com',
    phone: '1234567890',
    role: UserRole.employee,
    status: UserStatus.active,
  );

  const dummyCompany = Company(
    id: 1,
    name: 'Apex Infotech',
    contactPerson: 'Alice',
    phone: '9876543210',
    address: 'Indore',
    approval: ApprovalStatus.approved,
    isActive: true,
  );

  final providerOverrides = [
    pendingRequestsProvider.overrideWith((ref) => Stream.value(<ItemRequest>[])),
    allComplaintsProvider.overrideWith((ref) => Stream.value(<Complaint>[])),
    productsProvider.overrideWith((ref) => Stream.value(<Product>[])),
    companiesProvider.overrideWith((ref) => Stream.value(<Company>[dummyCompany])),
    approvedCompaniesProvider.overrideWith((ref) => Stream.value(<Company>[dummyCompany])),
    adminUpiConfigProvider.overrideWith((ref) => Stream.value(const AdminUpiConfig())),
    employeesProvider.overrideWith((ref) => Stream.value(<AppUser>[dummyUser])),
  ];

  testWidgets('AdminDashboardView hides bottom nav bar on mobile screens', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: providerOverrides,
        child: const MaterialApp(
          home: AdminDashboardView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify NavigationBar is completely absent on mobile
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);

    // Verify Top Bar actions: Inventory button and Unified Add button
    expect(find.byTooltip('Inventory'), findsOneWidget);
    expect(find.byTooltip('Add Company or Employee'), findsOneWidget);

    // Verify Admin Home content is displayed
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Management & Access'), findsOneWidget);
    expect(find.text('Corporate Clients'), findsWidgets);
    expect(find.text('Delivery & Employees'), findsOneWidget);

    // Open Unified Add popup menu
    await tester.tap(find.byTooltip('Add Company or Employee'));
    await tester.pumpAndSettle();

    expect(find.text('Add Company'), findsOneWidget);
    expect(find.text('Add Employee'), findsOneWidget);
  });

  testWidgets('AdminDashboardView shows NavigationRail with 4 destinations on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: providerOverrides,
        child: const MaterialApp(
          home: AdminDashboardView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify NavigationRail is mounted
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Verify rail destinations: Dashboard, Inventory, Companies, Employees
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventory'), findsWidgets); // Rail destination & tooltip
    expect(find.text('Companies'), findsOneWidget);
    expect(find.text('Employees'), findsOneWidget);
    // Bills destination should NOT exist on the rail
    expect(find.text('Bills'), findsNothing);
  });
}
