class Product {
  String? barcode;
  final String name;
  double purchasePrice;
  double salePrice;
  double stock;
  String? supplierName;
  String? supplierPhone;
  List<String> photoUrls;

  Product({
    required this.barcode,
    required this.name,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    required this.supplierName,
    required this.supplierPhone,
    this.photoUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'field name': barcode,
      'field name': name,
      'field name': purchasePrice,
      'field name': salePrice,
      'field name': stock,
      'field name': supplierName,
      'field name': supplierPhone,
      'field name': photoUrls,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcode: map['field name'] ?? '',
      name: map['field name'],
      purchasePrice: map['field name'] ?? 0.0,
      salePrice: map['field name'] ?? 0.0,
      stock: map['field name'] ?? 0.0,
      supplierName: map['field name'] ?? '',
      supplierPhone: map['field name'] ?? '',
      photoUrls: (map['field name'] is List)
          ? List<String>.from(map['field name'] ?? [])
          : [],
    );
  }
}
