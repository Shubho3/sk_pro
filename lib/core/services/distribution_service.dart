import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/item_request.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../repositories/company_repository.dart';
import '../repositories/complaint_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/request_repository.dart';

/// Coordinates the multi-table writes behind field actions:
/// distributing goods, collecting payments, recording requests and
/// raising complaints — keeping stock, balances and notifications in sync.
class DistributionService {
  DistributionService({
    required this.companies,
    required this.products,
    required this.requests,
    required this.payments,
    required this.complaints,
    required this.notifications,
    required this.invoices,
  });

  final CompanyRepository companies;
  final ProductRepository products;
  final RequestRepository requests;
  final PaymentRepository payments;
  final ComplaintRepository complaints;
  final NotificationRepository notifications;
  final InvoiceRepository invoices;

  int _parseId(dynamic id) =>
      id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0);

  /// Employee hands over items to a company. Reduces stock, and either records
  /// an immediate payment or adds the amount to the company's monthly bill.
  Future<void> distributeGoods({
    required dynamic companyId,
    required String companyName,
    required dynamic employeeId,
    required List<RequestLine> items,
    required PaymentMode paymentMode,
    PaymentMethod? paymentMethod,
    dynamic requestId,
  }) async {
    final cId = _parseId(companyId);
    final eId = _parseId(employeeId);
    final total = items.fold<double>(0, (acc, i) => acc + i.total);

    if (requestId != null) {
      await requests.fulfil(
        requestId,
        items: items,
        paymentMode: paymentMode,
        employeeId: eId,
      );
    } else {
      await requests.create(ItemRequest(
        id: 0,
        companyId: cId,
        companyName: companyName,
        employeeId: eId,
        items: items,
        paymentMode: paymentMode,
        status: RequestStatus.fulfilled,
      ));
    }

    for (final line in items) {
      if (line.productId > 0) {
        await products.adjustStock(line.productId, -line.qty);
      }
    }

    if (paymentMode == PaymentMode.payNow) {
      await payments.record(Payment(
        id: 0,
        companyId: cId,
        companyName: companyName,
        employeeId: eId,
        amount: total,
        method: paymentMethod ?? PaymentMethod.cash,
      ));
    } else {
      await companies.adjustOutstanding(cId, total);
    }

    await _notifyCompanyOwner(
      cId,
      title: 'Goods delivered',
      body: paymentMode == PaymentMode.payNow
          ? 'Items worth \u20b9${total.toStringAsFixed(0)} delivered and paid.'
          : 'Items worth \u20b9${total.toStringAsFixed(0)} delivered, added to your bill.',
      type: 'delivery',
    );
  }

  /// Employee records a walk-in sale.
  Future<void> recordWalkInSale({
    required dynamic employeeId,
    required List<RequestLine> items,
    required PaymentMethod method,
    String? customerName,
  }) async {
    final eId = _parseId(employeeId);
    final total = items.fold<double>(0, (acc, i) => acc + i.total);

    for (final line in items) {
      if (line.productId > 0) {
        await products.adjustStock(line.productId, -line.qty);
      }
    }

    await payments.record(Payment(
      id: 0,
      companyId: null,
      companyName: (customerName?.trim().isNotEmpty ?? false)
          ? customerName!.trim()
          : 'Walk-in',
      employeeId: eId,
      amount: total,
      method: method,
    ));
  }

  /// Employee collects a payment against the company's outstanding balance.
  Future<void> collectPayment({
    required dynamic companyId,
    required String companyName,
    required dynamic employeeId,
    required double amount,
    required PaymentMethod method,
    dynamic invoiceId,
  }) async {
    final cId = _parseId(companyId);
    final eId = _parseId(employeeId);

    if (invoiceId != null && _parseId(invoiceId) > 0) {
      final invId = _parseId(invoiceId);
      await payments.record(Payment(
        id: 0,
        companyId: cId,
        companyName: companyName,
        employeeId: eId,
        invoiceId: invId,
        amount: amount,
        method: method,
      ));
      await companies.adjustOutstanding(cId, -amount);
      await _applyToInvoice(invId, amount);
    } else {
      final companyInvoices = await invoices.getByCompany(cId);
      final unpaid = companyInvoices
          .where((i) => i.status != InvoiceStatus.paid && i.balance > 0)
          .toList()
        ..sort((a, b) => a.month.compareTo(b.month));

      double rem = amount;
      if (unpaid.isNotEmpty) {
        for (final inv in unpaid) {
          if (rem <= 0) break;
          final portion = rem > inv.balance ? inv.balance : rem;
          await payments.record(Payment(
            id: 0,
            companyId: cId,
            companyName: companyName,
            employeeId: eId,
            invoiceId: inv.id,
            amount: portion,
            method: method,
          ));
          await _applyToInvoice(inv.id, portion);
          rem -= portion;
        }
        await companies.adjustOutstanding(cId, -amount);
        if (rem > 0) {
          await payments.record(Payment(
            id: 0,
            companyId: cId,
            companyName: companyName,
            employeeId: eId,
            amount: rem,
            method: method,
          ));
        }
      } else {
        await payments.record(Payment(
          id: 0,
          companyId: cId,
          companyName: companyName,
          employeeId: eId,
          amount: amount,
          method: method,
        ));
        await companies.adjustOutstanding(cId, -amount);
      }
    }

    await _notifyCompanyOwner(
      cId,
      title: 'Payment recorded',
      body: '\u20b9${amount.toStringAsFixed(0)} received via ${method.name}.',
      type: 'payment',
    );
  }

  /// Records an on-visit request from a company.
  Future<void> takeRequest({
    required dynamic companyId,
    required String companyName,
    required dynamic employeeId,
    required List<RequestLine> items,
    required PaymentMode paymentMode,
  }) async {
    final cId = _parseId(companyId);
    final eId = _parseId(employeeId);

    await requests.create(ItemRequest(
      id: 0,
      companyId: cId,
      companyName: companyName,
      employeeId: eId,
      items: items,
      paymentMode: paymentMode,
      status: RequestStatus.pending,
    ));
    await notifications.create(AppNotification(
      id: 0,
      toRole: UserRole.admin.name,
      title: 'New item request',
      body: '$companyName requested ${items.length} item(s).',
      type: 'request',
    ));
  }

  /// A company raises its own request from the portal.
  Future<void> raiseCompanyRequest({
    required dynamic companyId,
    required String companyName,
    required List<RequestLine> items,
    required PaymentMode paymentMode,
  }) async {
    final cId = _parseId(companyId);

    await requests.create(ItemRequest(
      id: 0,
      companyId: cId,
      companyName: companyName,
      items: items,
      paymentMode: paymentMode,
      status: RequestStatus.pending,
    ));
    await notifications.create(AppNotification(
      id: 0,
      toRole: UserRole.admin.name,
      title: 'New item request',
      body: '$companyName requested ${items.length} item(s).',
      type: 'request',
    ));
  }

  /// A company records a payment against its bill from the portal.
  Future<void> payByCompany({
    required dynamic companyId,
    required String companyName,
    required double amount,
    required PaymentMethod method,
    dynamic invoiceId,
    String? transactionRef,
  }) async {
    final cId = _parseId(companyId);
    final invId = invoiceId != null ? _parseId(invoiceId) : null;

    if (invId != null && invId > 0) {
      await payments.record(Payment(
        id: 0,
        companyId: cId,
        companyName: companyName,
        invoiceId: invId,
        amount: amount,
        method: method,
        transactionRef: transactionRef,
      ));
      await companies.adjustOutstanding(cId, -amount);
      await _applyToInvoice(invId, amount);
    } else {
      final companyInvoices = await invoices.getByCompany(cId);
      final unpaid = companyInvoices
          .where((i) => i.status != InvoiceStatus.paid && i.balance > 0)
          .toList()
        ..sort((a, b) => a.month.compareTo(b.month));

      double rem = amount;
      if (unpaid.isNotEmpty) {
        for (final inv in unpaid) {
          if (rem <= 0) break;
          final portion = rem > inv.balance ? inv.balance : rem;
          await payments.record(Payment(
            id: 0,
            companyId: cId,
            companyName: companyName,
            invoiceId: inv.id,
            amount: portion,
            method: method,
            transactionRef: transactionRef,
          ));
          await _applyToInvoice(inv.id, portion);
          rem -= portion;
        }
        await companies.adjustOutstanding(cId, -amount);
        if (rem > 0) {
          await payments.record(Payment(
            id: 0,
            companyId: cId,
            companyName: companyName,
            amount: rem,
            method: method,
            transactionRef: transactionRef,
          ));
        }
      } else {
        await payments.record(Payment(
          id: 0,
          companyId: cId,
          companyName: companyName,
          amount: amount,
          method: method,
          transactionRef: transactionRef,
        ));
        await companies.adjustOutstanding(cId, -amount);
      }
    }

    await notifications.create(AppNotification(
      id: 0,
      toRole: UserRole.admin.name,
      title: 'Bill payment',
      body: '$companyName paid \u20b9${amount.toStringAsFixed(0)}.',
      type: 'payment',
    ));
  }

  /// Raises a complaint and notifies admins.
  Future<void> raiseComplaint({
    required dynamic raisedByUid,
    required String raisedByName,
    required UserRole raisedByRole,
    required String subject,
    required String description,
    dynamic companyId,
    dynamic employeeId,
  }) async {
    await complaints.create(Complaint(
      id: 0,
      raisedByUid: _parseId(raisedByUid),
      raisedByName: raisedByName,
      raisedByRole: raisedByRole,
      companyId: companyId != null ? _parseId(companyId) : null,
      employeeId: employeeId != null ? _parseId(employeeId) : null,
      subject: subject,
      description: description,
    ));
    await notifications.create(AppNotification(
      id: 0,
      toRole: UserRole.admin.name,
      title: 'New complaint',
      body: '$raisedByName: $subject',
      type: 'complaint',
    ));
  }

  /// Admin approves a company's request.
  Future<void> approveRequest(ItemRequest request) async {
    await requests.setStatus(request.id, RequestStatus.approved);
    await _notifyCompanyOwner(
      request.companyId,
      title: 'Request approved',
      body: 'Your request for ${request.items.length} item(s) was approved '
          'and will be delivered on your next visit.',
      type: 'request',
    );
  }

  /// Admin rejects a company's request.
  Future<void> rejectRequest(ItemRequest request) async {
    await requests.setStatus(request.id, RequestStatus.rejected);
    await _notifyCompanyOwner(
      request.companyId,
      title: 'Request rejected',
      body: 'Your request for ${request.items.length} item(s) was not approved.',
      type: 'request',
    );
  }

  Future<void> _applyToInvoice(dynamic invoiceId, double amount) async {
    if (invoiceId == null) return;
    final invoice = await invoices.getById(invoiceId);
    if (invoice == null) return;
    final paid = invoice.paid + amount;
    await invoices.applyPayment(
      invoiceId,
      paid,
      invoice.subtotal,
      invoiceStatusFor(invoice.subtotal, paid),
    );
  }

  Future<void> _notifyCompanyOwner(
    dynamic companyId, {
    required String title,
    required String body,
    required String type,
  }) async {
    final company = await companies.getById(companyId);
    final ownerUid = company?.ownerUid;
    if (ownerUid == null) return;
    await notifications.create(AppNotification(
      id: 0,
      toUid: ownerUid,
      title: title,
      body: body,
      type: type,
    ));
  }
}
