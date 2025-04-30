class Product {
  final String id;
  final String name;
  final double price;
  final int gstRate; // GST rate in percentage (5, 12, 18, 28)

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.gstRate,
  });

  // Calculate CGST amount
  double calculateCGST() {
    return (price * gstRate / 100) / 2;
  }

  // Calculate SGST amount
  double calculateSGST() {
    return (price * gstRate / 100) / 2;
  }

  // Calculate total price including GST
  double calculateTotalPrice() {
    return price + calculateCGST() + calculateSGST();
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      gstRate: data['gstRate'] ?? 18,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'gstRate': gstRate};
  }
}
