import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tea_stall/core/models/company.dart';
import 'package:smart_tea_stall/core/models/invoice.dart';
import 'package:smart_tea_stall/core/models/item_request.dart';
import 'package:smart_tea_stall/core/models/master_data.dart';
import 'package:smart_tea_stall/core/models/payment.dart';
import 'package:smart_tea_stall/core/models/payment_request.dart';
import 'package:smart_tea_stall/core/repositories/invoice_repository.dart';
import 'package:smart_tea_stall/core/repositories/payment_repository.dart';
import 'package:smart_tea_stall/core/repositories/request_repository.dart';
import 'package:smart_tea_stall/core/services/invoice_service.dart';

import 'package:smart_tea_stall/core/models/app_notification.dart';
import 'package:smart_tea_stall/core/repositories/company_repository.dart';
import 'package:smart_tea_stall/core/repositories/complaint_repository.dart';
import 'package:smart_tea_stall/core/repositories/notification_repository.dart';
import 'package:smart_tea_stall/core/repositories/product_repository.dart';
import 'package:smart_tea_stall/core/services/distribution_service.dart';

class _FakeRequestRepository implements RequestRepository {
  final List<ItemRequest> requests;
  _FakeRequestRepository(this.requests);

  @override
  Future<List<ItemRequest>> getByCompany(dynamic companyId) async => requests;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  final List<Payment> recorded = [];

  @override
  Future<int> record(Payment payment) async {
    final p = Payment(
      id: recorded.length + 1,
      companyId: payment.companyId,
      companyName: payment.companyName,
      employeeId: payment.employeeId,
      invoiceId: payment.invoiceId,
      amount: payment.amount,
      method: payment.method,
      transactionRef: payment.transactionRef,
      collectedAt: payment.collectedAt ?? DateTime.now(),
    );
    recorded.add(p);
    return p.id;
  }

  @override
  Future<List<Payment>> getByInvoice(dynamic invoiceId) async =>
      recorded.where((p) => p.invoiceId == invoiceId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInvoiceRepository implements InvoiceRepository {
  final Map<dynamic, Invoice> store = {};
  int _nextId = 1;

  @override
  Future<Invoice?> findByCompanyMonth(dynamic companyId, String month) async {
    return store.values.cast<Invoice?>().firstWhere(
          (i) => i?.companyId == companyId && i?.month == month,
          orElse: () => null,
        );
  }

  @override
  Future<List<Invoice>> getByCompany(dynamic companyId) async {
    return store.values.where((i) => i.companyId == companyId).toList();
  }

  @override
  Future<Invoice?> getById(dynamic id) async {
    return store[id] ??
        store.values.firstWhere((i) => i.id == id,
            orElse: () => throw Exception('Not found'));
  }

  @override
  Future<int> create(Invoice invoice) async {
    final id = _nextId++;
    store[id] = invoice.copyWith(id: id);
    return id;
  }

  @override
  Future<void> updateLines(
    dynamic id, {
    required List<InvoiceLine> lines,
    required double paid,
    required InvoiceStatus status,
  }) async {
    final inv = await getById(id);
    if (inv != null) {
      store[inv.id] = inv.copyWith(lines: lines, paid: paid, status: status);
    }
  }

  @override
  Future<void> applyPayment(
      dynamic id, double paid, double subtotal, InvoiceStatus status) async {
    final inv = await getById(id);
    if (inv != null) {
      store[inv.id] = inv.copyWith(paid: paid, status: status);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCompanyRepository implements CompanyRepository {
  double currentOutstanding = 0;

  @override
  Future<void> adjustOutstanding(dynamic companyId, double delta) async {
    currentOutstanding += delta;
  }

  @override
  Future<Company?> getById(dynamic id) async => Company(
        id: id is int ? id : (int.tryParse(id.toString()) ?? 1),
        name: 'Test Co',
        contactPerson: 'Admin',
        phone: '1234567890',
        address: 'HQ',
        outstanding: currentOutstanding,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> sent = [];

  @override
  Future<int> create(AppNotification notification) async {
    sent.add(notification);
    return sent.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Admin UPI Config & Barcode URI', () {
    test('AdminUpiConfig initializes with sound defaults', () {
      const config = AdminUpiConfig();
      expect(config.upiId, 'chaistall@upi');
      expect(config.payeeName, 'Indore Chai Company');
      expect(config.defaultNote, isNotNull);
    });

    test('buildUpiUri encodes parameters correctly into upi://pay URI', () {
      const config = AdminUpiConfig(
        upiId: 'vendor@oksbi',
        payeeName: 'Indore Chai Co',
        defaultNote: 'Monthly Bill',
      );

      final uri = config.buildUpiUri(amount: 1450.0);
      expect(uri.startsWith('upi://pay?'), isTrue);
      expect(uri, contains('pa=vendor%40oksbi'));
      expect(uri, contains('pn=Indore%20Chai%20Co'));
      expect(uri, contains('am=1450.00'));
      expect(uri, contains('cu=INR'));
      expect(uri, contains('tn=Monthly%20Bill'));
    });

    test('buildUpiUri handles merchant code and custom note', () {
      const config = AdminUpiConfig(
        upiId: 'chai@okhdfc',
        payeeName: 'Chai Station',
        merchantCode: '5411',
      );

      final uri = config.buildUpiUri(amount: 250, note: 'Tea August 2026');
      expect(uri, contains('mc=5411'));
      expect(uri, contains('tn=Tea%20August%202026'));
      expect(uri, contains('am=250.00'));
    });

    test('AdminUpiConfig serialization round-trip', () {
      const config = AdminUpiConfig(
        upiId: 'admin@upi',
        payeeName: 'My Chai Shop',
        merchantCode: '7299',
        defaultNote: 'Settlement',
      );

      final map = config.toMap();
      final restored = AdminUpiConfig.fromMap(map);

      expect(restored.upiId, config.upiId);
      expect(restored.payeeName, config.payeeName);
      expect(restored.merchantCode, config.merchantCode);
      expect(restored.defaultNote, config.defaultNote);
    });
  });

  group('PaymentRequest Model', () {
    test('Serialization and deserialization', () {
      const req = PaymentRequest(
        id: 1,
        companyId: 101,
        companyName: 'Tech Hub',
        invoiceId: 201,
        month: '2026-09',
        amount: 2200.0,
        upiId: 'chaistall@upi',
        payeeName: 'Indore Chai Company',
        note: 'Please clear September dues',
        status: PaymentRequestStatus.pending,
      );

      final map = req.toMap();
      expect(map['company_id'], 101);
      expect(map['amount'], 2200.0);
      expect(map['status'], 'pending');

      final restored = PaymentRequest.fromMap(map, 1);
      expect(restored.id, 1);
      expect(restored.companyName, 'Tech Hub');
      expect(restored.amount, 2200.0);
      expect(restored.status, PaymentRequestStatus.pending);
      expect(restored.month, '2026-09');

      final upiUri = restored.buildUpiUri();
      expect(upiUri, contains('pa=chaistall%40upi'));
      expect(upiUri, contains('am=2200.00'));
    });
  });

  group('Payment Model with transactionRef', () {
    test('Payment preserves transactionRef for UPI UTR tracking', () {
      final payment = Payment(
        id: 99,
        companyId: 101,
        companyName: 'Tech Hub',
        amount: 1500.0,
        method: PaymentMethod.upi,
        invoiceId: 101,
        transactionRef: 'UTR123456789012',
        collectedAt: DateTime(2026, 9, 10),
      );

      final map = payment.toMap();
      expect(map['transaction_ref'], 'UTR123456789012');
      expect(map['method'], 'upi');

      final restored = Payment.fromMap(map, 99);
      expect(restored.transactionRef, 'UTR123456789012');
      expect(restored.method, PaymentMethod.upi);
      expect(restored.amount, 1500.0);
    });
  });

  group('InvoiceService Auto Monthly Synchronization', () {
    test('generateForCompany generates invoices for past months', () async {
      const comp = Company(
        id: 101,
        name: 'Nexus Tech',
        contactPerson: 'Alex',
        phone: '9876543210',
        address: 'Floor 3',
        outstanding: 500,
      );

      final reqRepo = _FakeRequestRepository([
        ItemRequest(
          id: 1,
          companyId: 101,
          companyName: 'Nexus Tech',
          items: const [
            RequestLine(
              productId: 1,
              name: 'Cutting Chai',
              qty: 10,
              price: 15.0,
              unit: 'cup',
            ),
          ],
          paymentMode: PaymentMode.addToBill,
          status: RequestStatus.fulfilled,
          createdAt: DateTime(2026, 9, 2),
        ),
      ]);
      final payRepo = _FakePaymentRepository();
      final invRepo = _FakeInvoiceRepository();

      final service = InvoiceService(
        requests: reqRepo,
        payments: payRepo,
        invoices: invRepo,
      );

      await service.generateForCompany(company: comp, month: DateTime(2026, 9));

      // Invoices should have been generated and stored for the months
      expect(invRepo.store.isNotEmpty, isTrue);
    });
  });

  group('Invoice Status Derivation', () {
    test('invoiceStatusFor marks zero subtotal invoices as paid', () {
      expect(invoiceStatusFor(0, 0), InvoiceStatus.paid);
      expect(invoiceStatusFor(-10, 0), InvoiceStatus.paid);
    });

    test('invoiceStatusFor correctly categorizes unpaid, partial, and paid balances', () {
      expect(invoiceStatusFor(1000, 0), InvoiceStatus.unpaid);
      expect(invoiceStatusFor(1000, 400), InvoiceStatus.partial);
      expect(invoiceStatusFor(1000, 1000), InvoiceStatus.paid);
      expect(invoiceStatusFor(1000, 1200), InvoiceStatus.paid);
    });
  });

  group('DistributionService Invoice Auto-Allocation & UTR Tracking', () {
    test('payByCompany allocates payment across open unpaid invoices and marks them paid', () async {
      final compRepo = _FakeCompanyRepository();
      compRepo.currentOutstanding = 800;

      final invRepo = _FakeInvoiceRepository();
      // Setup two unpaid invoices: August (300) and September (500)
      invRepo.store[1] = const Invoice(
        id: 1,
        companyId: 1,
        companyName: 'Acme Corp',
        month: '2026-08',
        lines: [InvoiceLine(description: 'Tea', qty: 20, unitPrice: 15)],
        paid: 0,
        status: InvoiceStatus.unpaid,
      );
      invRepo.store[2] = const Invoice(
        id: 2,
        companyId: 1,
        companyName: 'Acme Corp',
        month: '2026-09',
        lines: [InvoiceLine(description: 'Snacks', qty: 25, unitPrice: 20)],
        paid: 0,
        status: InvoiceStatus.unpaid,
      );

      final payRepo = _FakePaymentRepository();
      final notifRepo = _FakeNotificationRepository();
      final reqRepo = _FakeRequestRepository([]);

      final distService = DistributionService(
        companies: compRepo,
        products: _FakeProductRepository(),
        requests: reqRepo,
        payments: payRepo,
        complaints: _FakeComplaintRepository(),
        notifications: notifRepo,
        invoices: invRepo,
      );

      // Client pays 800 with UTR reference without specifying invoiceId
      await distService.payByCompany(
        companyId: 1,
        companyName: 'Acme Corp',
        amount: 800,
        method: PaymentMethod.upi,
        transactionRef: 'UPI_UTR_998877665544',
      );

      // Both invoices should now be fully paid!
      final augInv = invRepo.store[1]!;
      final sepInv = invRepo.store[2]!;

      expect(augInv.paid, 300);
      expect(augInv.status, InvoiceStatus.paid);
      expect(augInv.balance, 0);

      expect(sepInv.paid, 500);
      expect(sepInv.status, InvoiceStatus.paid);
      expect(sepInv.balance, 0);

      // Payments were created with correct invoiceId and transactionRef
      expect(payRepo.recorded.length, 2);
      expect(payRepo.recorded[0].invoiceId, 1);
      expect(payRepo.recorded[0].amount, 300);
      expect(payRepo.recorded[0].transactionRef, 'UPI_UTR_998877665544');

      expect(payRepo.recorded[1].invoiceId, 2);
      expect(payRepo.recorded[1].amount, 500);
      expect(payRepo.recorded[1].transactionRef, 'UPI_UTR_998877665544');

      // Company outstanding is reduced by 800 to 0
      expect(compRepo.currentOutstanding, 0);
    });

    test('collectPayment allocates payment across open unpaid invoices when invoiceId is null', () async {
      final compRepo = _FakeCompanyRepository();
      compRepo.currentOutstanding = 250;

      final invRepo = _FakeInvoiceRepository();
      invRepo.store[3] = const Invoice(
        id: 3,
        companyId: 2,
        companyName: 'Beta LLC',
        month: '2026-09',
        lines: [InvoiceLine(description: 'Chai', qty: 10, unitPrice: 25)],
        paid: 0,
        status: InvoiceStatus.unpaid,
      );

      final payRepo = _FakePaymentRepository();
      final notifRepo = _FakeNotificationRepository();
      final reqRepo = _FakeRequestRepository([]);

      final distService = DistributionService(
        companies: compRepo,
        products: _FakeProductRepository(),
        requests: reqRepo,
        payments: payRepo,
        complaints: _FakeComplaintRepository(),
        notifications: notifRepo,
        invoices: invRepo,
      );

      await distService.collectPayment(
        companyId: 2,
        companyName: 'Beta LLC',
        employeeId: 1,
        amount: 250,
        method: PaymentMethod.cash,
      );

      final sepInv = invRepo.store[3]!;
      expect(sepInv.paid, 250);
      expect(sepInv.status, InvoiceStatus.paid);
      expect(sepInv.balance, 0);

      expect(payRepo.recorded.length, 1);
      expect(payRepo.recorded.first.invoiceId, 3);
    });
  });
}

class _FakeProductRepository implements ProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeComplaintRepository implements ComplaintRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
