class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageBase64;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageBase64,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageBase64: json['image_base64'],
    );
  }
}
