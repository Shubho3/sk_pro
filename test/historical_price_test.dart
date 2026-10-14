import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tea_stall/core/models/company.dart';
import 'package:smart_tea_stall/core/models/invoice.dart';
import 'package:smart_tea_stall/core/models/item_request.dart';
import 'package:smart_tea_stall/core/models/master_data.dart';
import 'package:smart_tea_stall/core/models/payment.dart';
import 'package:smart_tea_stall/core/repositories/invoice_repository.dart';
import 'package:smart_tea_stall/core/repositories/payment_repository.dart';
import 'package:smart_tea_stall/core/repositories/request_repository.dart';
import 'package:smart_tea_stall/core/services/invoice_service.dart';

class _FakeRequestRepository implements RequestRepository {
  final List<ItemRequest> requests;
  _FakeRequestRepository(this.requests);

  @override
  Future<List<ItemRequest>> getByCompany(dynamic companyId) async => requests;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<List<Payment>> getByInvoice(dynamic invoiceId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInvoiceRepository implements InvoiceRepository {
  Invoice? created;
  @override
  Future<Invoice?> findByCompanyMonth(dynamic companyId, String month) async => null;

  @override
  Future<int> create(Invoice invoice) async {
    created = invoice;
    return 123;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Historical Order Price & Unit Snapshots', () {
    test('RequestLine snapshots price and unit immutably', () {
      final line = RequestLine(
        productId: 1,
        name: 'Cutting Chai',
        qty: 15,
        price: 10.0,
        unit: 'cup',
      );

      expect(line.price, 10.0);
      expect(line.unit, 'cup');
      expect(line.total, 150.0);

      // Serialize to map and deserialize
      final map = line.toMap();
      expect(map['price'], 10.0);
      expect(map['unit'], 'cup');

      final restored = RequestLine.fromMap(map);
      expect(restored.price, 10.0);
      expect(restored.unit, 'cup');
      expect(restored.total, 150.0);
    });

    test('InvoiceService preserves distinct rate tiers when prices change during month', () async {
      final billingMonth = DateTime(2026, 9, 1);
      final reqRepo = _FakeRequestRepository([
        // Order 1: 20 cups at old price ₹10.00
        ItemRequest(
          id: 1,
          companyId: 101,
          companyName: 'Acme Corp',
          items: const [
            RequestLine(
              productId: 1,
              name: 'Cutting Chai',
              qty: 20,
              price: 10.0,
              unit: 'cup',
            ),
          ],
          paymentMode: PaymentMode.addToBill,
          status: RequestStatus.fulfilled,
          createdAt: DateTime(2026, 9, 5),
        ),
        // Order 2: 10 cups after price increase to ₹12.00
        ItemRequest(
          id: 2,
          companyId: 101,
          companyName: 'Acme Corp',
          items: const [
            RequestLine(
              productId: 1,
              name: 'Cutting Chai',
              qty: 10,
              price: 12.0,
              unit: 'cup',
            ),
          ],
          paymentMode: PaymentMode.addToBill,
          status: RequestStatus.fulfilled,
          createdAt: DateTime(2026, 9, 20),
        ),
      ]);

      final payRepo = _FakePaymentRepository();
      final invRepo = _FakeInvoiceRepository();

      final service = InvoiceService(
        requests: reqRepo,
        payments: payRepo,
        invoices: invRepo,
      );

      const company = Company(
        id: 101,
        name: 'Acme Corp',
        contactPerson: 'Rahul Sharma',
        phone: '9876543210',
        address: 'MG Road, Indore',
      );

      await service.generateForCompany(company: company, month: billingMonth);

      final generated = invRepo.created;
      expect(generated, isNotNull);
      // There must be 2 distinct lines for the 2 rate tiers, NOT 1 merged line with distorted rate
      expect(generated!.lines.length, 2);

      // Verify line 1: 20 cups @ ₹10 = ₹200
      final line1 = generated.lines.firstWhere((l) => l.unitPrice == 10.0);
      expect(line1.qty, 20);
      expect(line1.total, 200.0);

      // Verify line 2: 10 cups @ ₹12 = ₹120
      final line2 = generated.lines.firstWhere((l) => l.unitPrice == 12.0);
      expect(line2.qty, 10);
      expect(line2.total, 120.0);

      // Subtotal should be 200 + 120 = 320 (if merged at ₹12 it would have erroneously been 360)
      expect(generated.subtotal, 320.0);
    });
  });

  group('Master Data Defaults', () {
    test('Static default categories and units are populated', () {
      expect(MasterCategory.defaults, isNotEmpty);
      expect(MasterCategory.defaults.any((c) => c.name.contains('Chai')), isTrue);
      expect(MasterCategory.defaults.any((c) => c.name.contains('Coffee')), isTrue);

      expect(MasterUnit.defaults, isNotEmpty);
      expect(MasterUnit.defaults.any((u) => u.symbol == 'cup'), isTrue);
      expect(MasterUnit.defaults.any((u) => u.symbol == 'flask'), isTrue);
    });
  });
}
