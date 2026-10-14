enum InvoiceStatus { unpaid, partial, paid }

InvoiceStatus invoiceStatusFromString(String? value) =>
    InvoiceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvoiceStatus.unpaid,
    );

/// Derives an invoice's status from its totals.
InvoiceStatus invoiceStatusFor(double subtotal, double paid) {
  if (subtotal <= 0) return InvoiceStatus.paid;
  if (paid <= 0) return InvoiceStatus.unpaid;
  if (paid + 0.001 >= subtotal) return InvoiceStatus.paid;
  return InvoiceStatus.partial;
}

/// A single billed line on an invoice.
class InvoiceLine {
  final String description;
  final int qty;
  final double unitPrice;

  const InvoiceLine({
    required this.description,
    required this.qty,
    required this.unitPrice,
  });

  double get total => qty * unitPrice;

  factory InvoiceLine.fromMap(Map<String, dynamic> map) => InvoiceLine(
        description: (map['description'] ?? '').toString(),
        qty: (map['qty'] as num?)?.toInt() ?? 0,
        unitPrice:
            (map['unit_price'] ?? map['unitPrice'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'qty': qty,
        'unit_price': unitPrice,
        'total': total,
      };
}

/// A monthly bill for a company stored in `invoices` table.
class Invoice {
  final int id;
  final int companyId;
  final String companyName;

  /// Billing period key, formatted `yyyy-MM` (e.g. `2026-08`).
  final String month;
  final List<InvoiceLine> lines;
  final double paid;
  final InvoiceStatus status;

  final String? docUrl;
  final DateTime? generatedAt;

  const Invoice({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.month,
    required this.lines,
    this.paid = 0,
    this.status = InvoiceStatus.unpaid,
    this.docUrl,
    this.generatedAt,
  });

  double get subtotal => lines.fold(0, (acc, l) => acc + l.total);
  double get balance => subtotal - paid;

  factory Invoice.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final compIdVal = map['company_id'] ?? map['companyId'];
    final companyId = compIdVal is int
        ? compIdVal
        : (int.tryParse(compIdVal?.toString() ?? '') ?? 0);

    DateTime? parsedGeneratedAt;
    final g = map['generated_at'] ?? map['generatedAt'];
    if (g is DateTime) {
      parsedGeneratedAt = g;
    } else if (g is String) {
      parsedGeneratedAt = DateTime.tryParse(g);
    } else if (g is int) {
      parsedGeneratedAt = DateTime.fromMillisecondsSinceEpoch(g);
    }

    final rawLines = (map['lines'] ?? map['invoice_lines']) as List<dynamic>? ??
        const [];
    final parsedLines = <InvoiceLine>[];
    for (final item in rawLines) {
      if (item is Map) {
        try {
          parsedLines.add(
            InvoiceLine.fromMap(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } catch (_) {}
      }
    }

    return Invoice(
      id: id,
      companyId: companyId,
      companyName:
          (map['company_name'] ?? map['companyName'] ?? '').toString(),
      month: (map['month'] ?? '').toString(),
      lines: parsedLines,
      paid: (map['paid'] as num?)?.toDouble() ?? 0,
      status: invoiceStatusFromString(map['status']?.toString()),
      docUrl: (map['doc_url'] ?? map['docUrl'])?.toString(),
      generatedAt: parsedGeneratedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'company_id': companyId,
        'company_name': companyName,
        'month': month,
        'subtotal': subtotal,
        'paid': paid,
        'balance': balance,
        'status': status.name,
        if (docUrl != null) 'doc_url': docUrl,
        if (generatedAt != null) 'generated_at': generatedAt!.toIso8601String(),
      };

  Invoice copyWith({
    int? id,
    int? companyId,
    String? companyName,
    String? month,
    List<InvoiceLine>? lines,
    double? paid,
    InvoiceStatus? status,
    String? docUrl,
    DateTime? generatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      month: month ?? this.month,
      lines: lines ?? this.lines,
      paid: paid ?? this.paid,
      status: status ?? this.status,
      docUrl: docUrl ?? this.docUrl,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
