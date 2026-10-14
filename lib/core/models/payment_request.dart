enum PaymentRequestStatus { pending, paid, dismissed }

PaymentRequestStatus paymentRequestStatusFromString(String? value) =>
    PaymentRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentRequestStatus.pending,
    );

/// A payment settlement request sent from Admin to a Company stored in `payment_requests`.
class PaymentRequest {
  final int id;
  final int companyId;
  final String companyName;
  final int? invoiceId;
  final String month;
  final double amount;
  final String upiId;
  final String payeeName;
  final String? note;
  final PaymentRequestStatus status;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final String? transactionRef;

  const PaymentRequest({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.invoiceId,
    required this.month,
    required this.amount,
    required this.upiId,
    required this.payeeName,
    this.note,
    this.status = PaymentRequestStatus.pending,
    this.createdAt,
    this.paidAt,
    this.transactionRef,
  });

  factory PaymentRequest.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final compIdVal = map['company_id'] ?? map['companyId'];
    final companyId = compIdVal is int
        ? compIdVal
        : (int.tryParse(compIdVal?.toString() ?? '') ?? 0);

    final invIdVal = map['invoice_id'] ?? map['invoiceId'];
    final invoiceId = invIdVal == null
        ? null
        : (invIdVal is int ? invIdVal : int.tryParse(invIdVal.toString()));

    DateTime? parsedCreatedAt;
    final c = map['created_at'] ?? map['createdAt'];
    if (c is DateTime) {
      parsedCreatedAt = c;
    } else if (c is String) {
      parsedCreatedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    DateTime? parsedPaidAt;
    final p = map['paid_at'] ?? map['paidAt'];
    if (p is DateTime) {
      parsedPaidAt = p;
    } else if (p is String) {
      parsedPaidAt = DateTime.tryParse(p);
    } else if (p is int) {
      parsedPaidAt = DateTime.fromMillisecondsSinceEpoch(p);
    }

    return PaymentRequest(
      id: id,
      companyId: companyId,
      companyName:
          (map['company_name'] ?? map['companyName'] ?? '').toString(),
      invoiceId: invoiceId,
      month: (map['month'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      upiId: (map['upi_id'] ?? map['upiId'] ?? '').toString(),
      payeeName: (map['payee_name'] ?? map['payeeName'] ?? '').toString(),
      note: map['note']?.toString(),
      status: paymentRequestStatusFromString(map['status']?.toString()),
      createdAt: parsedCreatedAt,
      paidAt: parsedPaidAt,
      transactionRef: (map['transaction_ref'] ?? map['transactionRef'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'company_id': companyId,
        'company_name': companyName,
        if (invoiceId != null) 'invoice_id': invoiceId,
        'month': month,
        'amount': amount,
        'upi_id': upiId,
        'payee_name': payeeName,
        if (note != null) 'note': note,
        'status': status.name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
        if (transactionRef != null) 'transaction_ref': transactionRef,
      };

  /// Constructs the standard UPI deep-link URI.
  String buildUpiUri() {
    final cleanId = Uri.encodeComponent(upiId.trim());
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote =
        Uri.encodeComponent((note ?? 'Chai Subscription $month').trim());
    final cleanAmount = amount.toStringAsFixed(2);
    return 'upi://pay?pa=$cleanId&pn=$cleanName&am=$cleanAmount&cu=INR&tn=$cleanNote';
  }
}
