import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_tea_stall/core/models/app_user.dart';
import 'package:smart_tea_stall/core/models/company.dart';
import 'package:smart_tea_stall/core/models/invoice.dart';
import 'package:smart_tea_stall/core/models/item_request.dart';
import 'package:smart_tea_stall/core/models/master_data.dart';
import 'package:smart_tea_stall/core/providers/auth_providers.dart';
import 'package:smart_tea_stall/core/providers/repository_providers.dart';
import 'package:smart_tea_stall/core/repositories/request_repository.dart';
import 'package:smart_tea_stall/ui/views/admin/customer_bill_screen.dart';
import 'package:smart_tea_stall/ui/views/admin/requests_view.dart';
import 'package:smart_tea_stall/ui/views/auth/pending_view.dart';
import 'package:smart_tea_stall/ui/views/office/upi_payment_dialog.dart';

class _TestRequestRepo implements RequestRepository {
  final List<dynamic> deletedIds = [];

  @override
  Future<void> delete(dynamic id) async {
    deletedIds.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('UpiPaymentDialog renders QR barcode, UPI details, and pay buttons',
      (tester) async {
    const testConfig = AdminUpiConfig(
      upiId: 'chaistall@upi',
      payeeName: 'Indore Chai Company',
      defaultNote: 'September Bill',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUpiConfigProvider.overrideWith((ref) => Stream.value(testConfig)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UpiPaymentDialog(
              companyId: 123,
              companyName: 'Acme Technologies',
              amount: 1250.0,
              invoiceMonth: '2026-09',
              upiConfig: testConfig,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog elements
    expect(find.text('UPI Payment'), findsOneWidget);
    expect(find.text('Settling 2026-09 Bill'), findsOneWidget);
    expect(find.text('TOTAL PAYABLE'), findsOneWidget);
    expect(find.textContaining('1,250'), findsWidgets);

    // Verify QR Barcode is mounted
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Indore Chai Company'), findsOneWidget);
    expect(find.text('chaistall@upi'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Pay via UPI App'), findsOneWidget);
    expect(find.text('I Have Paid (Confirm)'), findsOneWidget);
  });

  testWidgets('CustomerBillScreen mounts with customer selector and outstanding cards',
      (tester) async {
    const testCompany = Company(
      id: 1,
      name: 'Alpha Systems',
      contactPerson: 'Sarah',
      phone: '9876543210',
      address: 'Suite 401',
      outstanding: 2400.0,
    );

    final nowKey = DateFormat('yyyy-MM').format(DateTime.now());
    final testInvoice = Invoice(
      id: 1,
      companyId: 1,
      companyName: 'Alpha Systems',
      month: nowKey,
      lines: const [
        InvoiceLine(description: 'Cutting Chai', qty: 20, unitPrice: 15.0),
      ],
      paid: 0,
      status: InvoiceStatus.unpaid,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvedCompaniesProvider
              .overrideWith((ref) => Stream.value([testCompany])),
          companyInvoicesProvider(1)
              .overrideWith((ref) => Stream.value([testInvoice])),
          companyPaymentsProvider(1)
              .overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: CustomerBillScreen(initialCompanyId: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Customer Billing'), findsOneWidget);
    expect(find.text('OUTSTANDING SUMMARY'), findsOneWidget);
    expect(find.text('Alpha Systems'), findsWidgets);
    expect(find.text('Unpaid (1)'), findsOneWidget);
    expect(find.text('Paid (0)'), findsOneWidget);
    expect(find.text('Get PDF'), findsOneWidget);
    expect(find.text('Request to Pay'), findsOneWidget);
    expect(find.text('Select Date'), findsOneWidget);
  });

  testWidgets('CustomerBillScreen hides inner AppBar when showAppBar: false',
      (tester) async {
    const testCompany = Company(
      id: 2,
      name: 'Beta Labs',
      contactPerson: 'Ken',
      phone: '9876543210',
      address: 'Suite 200',
      outstanding: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvedCompaniesProvider
              .overrideWith((ref) => Stream.value([testCompany])),
          companyInvoicesProvider(2)
              .overrideWith((ref) => Stream.value([])),
          companyPaymentsProvider(2)
              .overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: CustomerBillScreen(
            initialCompanyId: 2,
            showAppBar: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // With showAppBar: false, inner Customer Billing AppBar is not rendered
    expect(find.text('Customer Billing'), findsNothing);
    expect(find.text('OUTSTANDING SUMMARY'), findsOneWidget);
  });

  testWidgets(
      'CustomerBillScreen defaults to current month filter and allows tab and month switching',
      (tester) async {
    final now = DateTime.now();
    final nowKey = DateFormat('yyyy-MM').format(now);
    const pastKey = '2024-01';

    const testCompany = Company(
      id: 3,
      name: 'Gamma Innovations',
      contactPerson: 'Dev',
      phone: '9876543210',
      address: 'Floor 3',
      outstanding: 5000.0,
    );

    final currentInv = Invoice(
      id: 10,
      companyId: 3,
      companyName: 'Gamma Innovations',
      month: nowKey,
      lines: const [
        InvoiceLine(description: 'Special Chai', qty: 10, unitPrice: 20.0),
      ],
      paid: 0,
      status: InvoiceStatus.unpaid,
    );

    final pastInv = Invoice(
      id: 11,
      companyId: 3,
      companyName: 'Gamma Innovations',
      month: pastKey,
      lines: const [
        InvoiceLine(description: 'Ginger Chai', qty: 15, unitPrice: 15.0),
      ],
      paid: 0,
      status: InvoiceStatus.unpaid,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvedCompaniesProvider
              .overrideWith((ref) => Stream.value([testCompany])),
          companyInvoicesProvider(3)
              .overrideWith((ref) => Stream.value([currentInv, pastInv])),
          companyPaymentsProvider(3)
              .overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: CustomerBillScreen(initialCompanyId: 3),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Current month is selected by default, so only current invoice card is visible in unpaid tab
    expect(find.text('Unpaid (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey(10)), findsOneWidget);
    expect(find.byKey(const ValueKey(11)), findsNothing);

    // Switch to "All Months" filter chip
    final allMonthsChip = find.text('All Months');
    expect(allMonthsChip, findsOneWidget);
    await tester.tap(allMonthsChip);
    await tester.pumpAndSettle();

    // Now both current and past invoices should be visible in unpaid tab
    expect(find.text('Unpaid (2)'), findsOneWidget);
    expect(find.byKey(const ValueKey(10)), findsOneWidget);
    expect(find.byKey(const ValueKey(11)), findsOneWidget);

    // Switch to Paid tab
    await tester.tap(find.text('Paid (0)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No paid invoices found'), findsOneWidget);

    // Switch back to Unpaid tab
    await tester.tap(find.text('Unpaid (2)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey(10)), findsOneWidget);
  });

  testWidgets('AdminRequestsView clears processed requests upon confirmation',
      (tester) async {
    final fakeRepo = _TestRequestRepo();

    final pendingReq = ItemRequest(
      id: 1,
      companyId: 1,
      companyName: 'Company 1',
      employeeId: 1,
      paymentMode: PaymentMode.addToBill,
      status: RequestStatus.pending,
      items: const [RequestLine(productId: 1, name: 'Chai', price: 15, qty: 2)],
      createdAt: DateTime.now(),
    );

    final fulfilledReq = ItemRequest(
      id: 2,
      companyId: 1,
      companyName: 'Company 1',
      employeeId: 1,
      paymentMode: PaymentMode.addToBill,
      status: RequestStatus.fulfilled,
      items: const [RequestLine(productId: 1, name: 'Chai', price: 15, qty: 1)],
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingRequestsProvider
              .overrideWith((ref) => Stream.value([pendingReq])),
          processedRequestsProvider
              .overrideWith((ref) => Stream.value([fulfilledReq])),
          requestRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminRequestsView()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pending approval'), findsOneWidget);
    expect(find.text('Processed & History'), findsOneWidget);
    expect(find.text('Clear All Processed'), findsOneWidget);

    // Tap "Clear All Processed"
    await tester.tap(find.text('Clear All Processed'));
    await tester.pumpAndSettle();

    // Dialog opens
    expect(find.text('Clear Processed Requests?'), findsOneWidget);
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    // Verify repository delete was called with processed request id
    expect(fakeRepo.deletedIds, contains(2));
    expect(fakeRepo.deletedIds, isNot(contains(1)));
  });

  testWidgets('PendingView renders account disabled state for disabled employee',
      (tester) async {
    const disabledUser = AppUser(
      id: 1,
      authId: 'u_disabled',
      userId: 'u_disabled',
      name: 'Disabled Guy',
      email: 'disabled@stall.com',
      phone: '1111111111',
      role: UserRole.employee,
      status: UserStatus.disabled,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUserProvider.overrideWith((ref) => Stream.value(disabledUser)),
        ],
        child: const MaterialApp(
          home: PendingView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT DISABLED'), findsOneWidget);
    expect(find.text('Account Disabled'), findsOneWidget);
    expect(
        find.textContaining('disabled by the administrator'), findsOneWidget);
  });

  testWidgets('PendingView renders awaiting verification state for pending user',
      (tester) async {
    const pendingUser = AppUser(
      id: 2,
      authId: 'u_pending',
      userId: 'u_pending',
      name: 'Pending Guy',
      email: 'pending@stall.com',
      phone: '2222222222',
      role: UserRole.employee,
      status: UserStatus.pending,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUserProvider.overrideWith((ref) => Stream.value(pendingUser)),
        ],
        child: const MaterialApp(
          home: PendingView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APPROVAL PENDING'), findsOneWidget);
    expect(find.text('Awaiting Verification'), findsOneWidget);
    expect(
        find.textContaining('awaiting administrator approval'), findsOneWidget);
  });
}
