import 'package:intl/intl.dart';

import '../models/company.dart';
import '../models/invoice.dart';
import '../models/item_request.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/request_repository.dart';

/// Builds monthly invoices for a company by aggregating the "add to bill"
/// requests that were actually delivered in that month.
class InvoiceService {
  InvoiceService({
    required this.requests,
    required this.payments,
    required this.invoices,
  });

  final RequestRepository requests;
  final PaymentRepository payments;
  final InvoiceRepository invoices;

  static InvoiceStatus statusFor(double subtotal, double paid) =>
      invoiceStatusFor(subtotal, paid);

  Future<int> generateForCompany({
    required Company company,
    required DateTime month,
    bool createIfEmpty = true,
  }) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final monthKey = DateFormat('yyyy-MM').format(start);

    final companyRequests = await requests.getByCompany(company.id);
    final billable = companyRequests.where((r) =>
        r.paymentMode == PaymentMode.addToBill &&
        r.status == RequestStatus.fulfilled &&
        r.createdAt != null &&
        !r.createdAt!.isBefore(start) &&
        r.createdAt!.isBefore(end));

    final agg = <String, _LineAgg>{};
    for (final r in billable) {
      for (final item in r.items) {
        final key =
            '${item.name}__${item.price.toStringAsFixed(2)}__${item.unit}';
        final a = agg.putIfAbsent(
          key,
          () => _LineAgg(
            name: item.name,
            unitPrice: item.price,
            unit: item.unit,
          ),
        );
        a.qty += item.qty;
      }
    }
    final lines = agg.values
        .map((a) {
          final desc = (a.unit.isNotEmpty && a.unit != 'unit')
              ? '${a.name} (${a.unit})'
              : a.name;
          return InvoiceLine(
            description: desc,
            qty: a.qty,
            unitPrice: a.unitPrice,
          );
        })
        .toList()
      ..sort((a, b) => a.description.compareTo(b.description));

    final subtotal = lines.fold<double>(0, (acc, l) => acc + l.total);
    final existing = await invoices.findByCompanyMonth(company.id, monthKey);

    if (existing == null) {
      if (!createIfEmpty && lines.isEmpty) {
        return 0;
      }
      return invoices.create(Invoice(
        id: 0,
        companyId: company.id,
        companyName: company.name,
        month: monthKey,
        lines: lines,
        paid: 0,
        status: invoiceStatusFor(subtotal, 0),
      ));
    }

    // Refresh existing invoice lines
    await invoices.updateLines(
      existing.id,
      lines: lines,
      paid: existing.paid,
      status: invoiceStatusFor(subtotal, existing.paid),
    );
    return existing.id;
  }
}

class _LineAgg {
  _LineAgg({
    required this.name,
    required this.unitPrice,
    required this.unit,
  });

  final String name;
  final double unitPrice;
  final String unit;
  int qty = 0;
}
