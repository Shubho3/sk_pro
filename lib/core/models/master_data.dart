/// A product category managed in Master Data stored in `master_categories`.
class MasterCategory {
  final int id;
  final String name;
  final String description;
  final int order;

  const MasterCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.order = 0,
  });

  factory MasterCategory.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    return MasterCategory(
      id: id,
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      order: ((map['sort_order'] ?? map['order']) as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'sort_order': order,
      };

  MasterCategory copyWith({
    int? id,
    String? name,
    String? description,
    int? order,
  }) =>
      MasterCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        order: order ?? this.order,
      );

  /// Default static categories.
  static const List<MasterCategory> defaults = [
    MasterCategory(
      id: 1,
      name: 'Chai & Tea',
      description: 'Hot cutting chai, masala chai, ginger chai, green tea',
      order: 1,
    ),
    MasterCategory(
      id: 2,
      name: 'Coffee',
      description: 'Filter coffee, espresso, cold coffee',
      order: 2,
    ),
    MasterCategory(
      id: 3,
      name: 'Snacks & Bakery',
      description: 'Samosa, kachori, poha, cookies, toasts',
      order: 3,
    ),
    MasterCategory(
      id: 4,
      name: 'Cold Beverages',
      description: 'Lemonade, iced tea, juices, water bottles',
      order: 4,
    ),
    MasterCategory(
      id: 5,
      name: 'Supplies & Disposables',
      description: 'Paper cups, stirrers, napkins, sugar sachets',
      order: 5,
    ),
  ];
}

/// A unit of measurement managed in Master Data stored in `master_units`.
class MasterUnit {
  final int id;
  final String name;
  final String symbol;
  final int order;

  const MasterUnit({
    required this.id,
    required this.name,
    required this.symbol,
    this.order = 0,
  });

  factory MasterUnit.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    return MasterUnit(
      id: id,
      name: (map['name'] ?? '') as String,
      symbol: (map['symbol'] ?? (map['name'] ?? 'unit')) as String,
      order: ((map['sort_order'] ?? map['order']) as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'symbol': symbol,
        'sort_order': order,
      };

  MasterUnit copyWith({
    int? id,
    String? name,
    String? symbol,
    int? order,
  }) =>
      MasterUnit(
        id: id ?? this.id,
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        order: order ?? this.order,
      );

  /// Default static units.
  static const List<MasterUnit> defaults = [
    MasterUnit(id: 1, name: 'Cup', symbol: 'cup', order: 1),
    MasterUnit(id: 2, name: 'Flask (10 cups)', symbol: 'flask', order: 2),
    MasterUnit(id: 3, name: 'Plate', symbol: 'plate', order: 3),
    MasterUnit(id: 4, name: 'Piece', symbol: 'pc', order: 4),
    MasterUnit(id: 5, name: 'Packet', symbol: 'pkt', order: 5),
    MasterUnit(id: 6, name: 'Kilogram', symbol: 'kg', order: 6),
    MasterUnit(id: 7, name: 'Liter', symbol: 'L', order: 7),
  ];
}

/// Vendor UPI configuration managed exclusively by the admin stored in `app_settings` (key='upi_config').
class AdminUpiConfig {
  final String upiId;
  final String payeeName;
  final String? merchantCode;
  final String? defaultNote;

  const AdminUpiConfig({
    this.upiId = 'chaistall@upi',
    this.payeeName = 'Indore Chai Company',
    this.merchantCode,
    this.defaultNote = 'Chai Subscription Settlement',
  });

  factory AdminUpiConfig.fromMap(Map<String, dynamic> map) => AdminUpiConfig(
        upiId: (map['upiId'] ?? 'chaistall@upi') as String,
        payeeName: (map['payeeName'] ?? 'Indore Chai Company') as String,
        merchantCode: map['merchantCode'] as String?,
        defaultNote:
            (map['defaultNote'] ?? 'Chai Subscription Settlement') as String?,
      );

  Map<String, dynamic> toMap() => {
        'upiId': upiId,
        'payeeName': payeeName,
        if (merchantCode != null) 'merchantCode': merchantCode,
        if (defaultNote != null) 'defaultNote': defaultNote,
      };

  AdminUpiConfig copyWith({
    String? upiId,
    String? payeeName,
    String? merchantCode,
    String? defaultNote,
  }) =>
      AdminUpiConfig(
        upiId: upiId ?? this.upiId,
        payeeName: payeeName ?? this.payeeName,
        merchantCode: merchantCode ?? this.merchantCode,
        defaultNote: defaultNote ?? this.defaultNote,
      );

  /// Generates the standard deep-link URI for Indian UPI payments.
  String buildUpiUri({required double amount, String? note}) {
    final cleanId = Uri.encodeComponent(upiId.trim());
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote =
        Uri.encodeComponent((note ?? defaultNote ?? 'Chai Settlement').trim());
    final cleanAmount = amount.toStringAsFixed(2);
    final mc = (merchantCode != null && merchantCode!.trim().isNotEmpty)
        ? '&mc=${Uri.encodeComponent(merchantCode!.trim())}'
        : '';
    return 'upi://pay?pa=$cleanId&pn=$cleanName&am=$cleanAmount&cu=INR&tn=$cleanNote$mc';
  }
}
