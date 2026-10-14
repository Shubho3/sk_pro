/// How a payment was collected.
enum PaymentMethod { cash, upi, addedToBill }

PaymentMethod paymentMethodFromString(String? value) =>
    PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );

/// A payment recorded in `payments` table.
class Payment {
  final int id;
  final int? companyId;
  final String companyName;
  final int? employeeId;
  final int? invoiceId;
  final double amount;
  final PaymentMethod method;
  final DateTime? collectedAt;
  final String? transactionRef;

  const Payment({
    required this.id,
    this.companyId,
    required this.companyName,
    this.employeeId,
    this.invoiceId,
    required this.amount,
    required this.method,
    this.collectedAt,
    this.transactionRef,
  });

  factory Payment.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final compIdVal = map['company_id'] ?? map['companyId'];
    final companyId = compIdVal == null
        ? null
        : (compIdVal is int ? compIdVal : int.tryParse(compIdVal.toString()));

    final empIdVal = map['employee_id'] ?? map['employeeId'];
    final employeeId = empIdVal == null
        ? null
        : (empIdVal is int ? empIdVal : int.tryParse(empIdVal.toString()));

    final invIdVal = map['invoice_id'] ?? map['invoiceId'];
    final invoiceId = invIdVal == null
        ? null
        : (invIdVal is int ? invIdVal : int.tryParse(invIdVal.toString()));

    DateTime? parsedCollectedAt;
    final c = map['collected_at'] ?? map['collectedAt'];
    if (c is DateTime) {
      parsedCollectedAt = c;
    } else if (c is String) {
      parsedCollectedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCollectedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    return Payment(
      id: id,
      companyId: companyId,
      companyName:
          (map['company_name'] ?? map['companyName'] ?? '').toString(),
      employeeId: employeeId,
      invoiceId: invoiceId,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: paymentMethodFromString(map['method']?.toString()),
      collectedAt: parsedCollectedAt,
      transactionRef: (map['transaction_ref'] ?? map['transactionRef'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (companyId != null) 'company_id': companyId,
        'company_name': companyName,
        if (employeeId != null) 'employee_id': employeeId,
        if (invoiceId != null) 'invoice_id': invoiceId,
        'amount': amount,
        'method': method.name,
        if (transactionRef != null) 'transaction_ref': transactionRef,
        if (collectedAt != null) 'collected_at': collectedAt!.toIso8601String(),
      };
}
