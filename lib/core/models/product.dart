/// A sellable/distributable product stored at `products` table.
class Product {
  final int id;
  final String name;
  final String category;

  /// Unit of measure, e.g. `cup`, `plate`, `packet`.
  final String unit;
  final double price;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.stock,
  });

  factory Product.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    return Product(
      id: id,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      unit: (map['unit'] ?? 'unit') as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'unit': unit,
        'price': price,
        'stock': stock,
      };

  Product copyWith({
    int? id,
    String? name,
    String? category,
    String? unit,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }
}
