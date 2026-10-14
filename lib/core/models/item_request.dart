/// How a company wants to settle a requested item.
enum PaymentMode { payNow, addToBill }

/// Lifecycle of an item request raised by a company.
enum RequestStatus { pending, approved, fulfilled, rejected }

PaymentMode paymentModeFromString(String? value) =>
    PaymentMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMode.addToBill,
    );

RequestStatus requestStatusFromString(String? value) =>
    RequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequestStatus.pending,
    );

/// A single line item within a request.
class RequestLine {
  final int productId;
  final String name;
  final int qty;
  final double price;
  final String unit;

  const RequestLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
    this.unit = 'unit',
  });

  double get total => qty * price;

  factory RequestLine.fromMap(Map<String, dynamic> map) {
    final pidVal = map['product_id'] ?? map['productId'];
    final pid = pidVal is int
        ? pidVal
        : (int.tryParse(pidVal?.toString() ?? '') ?? 0);

    return RequestLine(
      productId: pid,
      name: (map['name'] ?? '').toString(),
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      unit: (map['unit'] ?? 'unit').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'name': name,
        'qty': qty,
        'price': price,
        'unit': unit,
      };
}

/// An on-visit item request raised by a company. Stored at `requests` table.
class ItemRequest {
  final int id;
  final int companyId;
  final String companyName;
  final int? employeeId;
  final List<RequestLine> items;
  final PaymentMode paymentMode;
  final RequestStatus status;
  final DateTime? createdAt;

  const ItemRequest({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.employeeId,
    required this.items,
    required this.paymentMode,
    this.status = RequestStatus.pending,
    this.createdAt,
  });

  double get total => items.fold(0, (acc, i) => acc + i.total);

  factory ItemRequest.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final compIdVal = map['company_id'] ?? map['companyId'];
    final companyId = compIdVal is int
        ? compIdVal
        : (int.tryParse(compIdVal?.toString() ?? '') ?? 0);

    final empIdVal = map['employee_id'] ?? map['employeeId'];
    final employeeId = empIdVal == null
        ? null
        : (empIdVal is int ? empIdVal : int.tryParse(empIdVal.toString()));

    DateTime? parsedCreatedAt;
    final c = map['created_at'] ?? map['createdAt'];
    if (c is DateTime) {
      parsedCreatedAt = c;
    } else if (c is String) {
      parsedCreatedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    final rawItems = (map['items'] ?? map['request_lines']) as List<dynamic>? ??
        const [];
    final parsedItems = <RequestLine>[];
    for (final item in rawItems) {
      if (item is Map) {
        try {
          parsedItems.add(
            RequestLine.fromMap(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } catch (_) {}
      }
    }

    return ItemRequest(
      id: id,
      companyId: companyId,
      companyName:
          (map['company_name'] ?? map['companyName'] ?? '').toString(),
      employeeId: employeeId,
      items: parsedItems,
      paymentMode: paymentModeFromString(
          (map['payment_mode'] ?? map['paymentMode'])?.toString()),
      status: requestStatusFromString(map['status']?.toString()),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'company_id': companyId,
        'company_name': companyName,
        if (employeeId != null) 'employee_id': employeeId,
        'payment_mode': paymentMode.name,
        'status': status.name,
        'total': total,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  ItemRequest copyWith({
    int? id,
    int? companyId,
    String? companyName,
    int? employeeId,
    List<RequestLine>? items,
    PaymentMode? paymentMode,
    RequestStatus? status,
    DateTime? createdAt,
  }) {
    return ItemRequest(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      employeeId: employeeId ?? this.employeeId,
      items: items ?? this.items,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
