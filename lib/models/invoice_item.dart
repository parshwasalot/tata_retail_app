import 'product.dart';

class InvoiceItem {
  final Product product;
  final int quantity;

  InvoiceItem({required this.product, required this.quantity});

  // Calculate base price (without GST)
  double calculateItemPrice() {
    return product.price * quantity;
  }

  // Calculate CGST (Central GST)
  double calculateCGST() {
    return (product.price * quantity * product.gstRate / 100) / 2;
  }

  // Calculate SGST (State GST)
  double calculateSGST() {
    return (product.price * quantity * product.gstRate / 100) / 2;
  }

  // Calculate total price with GST
  double calculateTotalPrice() {
    return calculateItemPrice() + calculateCGST() + calculateSGST();
  }

  // Create a copy with updated quantity
  InvoiceItem copyWith({int? quantity}) {
    return InvoiceItem(product: product, quantity: quantity ?? this.quantity);
  }

  // Factory constructor to create an InvoiceItem from a map
  factory InvoiceItem.fromMap(Map<String, dynamic> map, Product product) {
    return InvoiceItem(product: product, quantity: map['quantity'] ?? 0);
  }

  // Convert InvoiceItem to a map for storing in database
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'price': product.price,
      'gstRate': product.gstRate,
      'quantity': quantity,
      'cgst': calculateCGST(),
      'sgst': calculateSGST(),
      'totalAmount': calculateTotalPrice(),
    };
  }
}
