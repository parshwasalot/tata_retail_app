import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_item.dart';
import 'product.dart';
import '../services/product_service.dart';

class Invoice {
  String id;
  String customerId;
  String customerName;
  List<InvoiceItem> items;
  DateTime timestamp;
  String cashierName;

  Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.timestamp,
    required this.cashierName,
  });

  // Calculate subtotal (sum of all items without GST)
  double calculateSubtotal() {
    return items.fold(0, (sum, item) => sum + item.calculateItemPrice());
  }

  // Calculate total CGST
  double calculateTotalCGST() {
    return items.fold(0, (sum, item) => sum + item.calculateCGST());
  }

  // Calculate total SGST
  double calculateTotalSGST() {
    return items.fold(0, (sum, item) => sum + item.calculateSGST());
  }

  // Calculate grand total (with GST)
  double calculateGrandTotal() {
    return items.fold(0, (sum, item) => sum + item.calculateTotalPrice());
  }

  // Create Invoice from Firestore document
  static Future<Invoice> fromFirestore(
    DocumentSnapshot doc, {
    ProductService? productService,
  }) async {
    final data = doc.data() as Map<String, dynamic>;
    final productService = ProductService();

    // Process items
    List<InvoiceItem> itemsList = [];
    List<dynamic> itemsData = data['items'] ?? [];

    for (var itemData in itemsData) {
      final productId = itemData['productId'];
      final quantity = itemData['quantity'] ?? 0;

      try {
        // Get product using product service
        final product = await productService.getProductById(productId);
        if (product != null) {
          itemsList.add(InvoiceItem(product: product, quantity: quantity));
        }
      } catch (e) {
        // If product not found, create a placeholder product
        final product = Product(
          id: productId,
          name: itemData['productName'] ?? 'Unknown Product',
          price: itemData['price'] ?? 0.0,
          gstRate: itemData['gstRate'] ?? 0,
        );
        itemsList.add(InvoiceItem(product: product, quantity: quantity));
      }
    }

    return Invoice(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Unknown Customer',
      items: itemsList,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashierName: data['cashierName'] ?? 'Unknown Cashier',
    );
  }

  // Add a fromJson method that works with the map data
  static Future<Invoice> fromJson(
    Map<String, dynamic> data, {
    ProductService? productService,
  }) async {
    final prodService = productService ?? ProductService();

    // Process items
    List<InvoiceItem> itemsList = [];
    List<dynamic> itemsData = data['items'] ?? [];

    for (var itemData in itemsData) {
      final productId = itemData['productId'];
      final quantity = itemData['quantity'] ?? 0;

      try {
        // Get product using product service
        final product = await prodService.getProductById(productId);
        if (product != null) {
          itemsList.add(InvoiceItem(product: product, quantity: quantity));
        }
      } catch (e) {
        // If product not found, create a placeholder product
        final product = Product(
          id: productId,
          name: itemData['productName'] ?? 'Unknown Product',
          price: itemData['price'] ?? 0.0,
          gstRate: itemData['gstRate'] ?? 0,
        );
        itemsList.add(InvoiceItem(product: product, quantity: quantity));
      }
    }

    return Invoice(
      id: data['id'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Unknown Customer',
      items: itemsList,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashierName: data['cashierName'] ?? 'Unknown Cashier',
    );
  }

  // Convert Invoice to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'timestamp': timestamp,
      'cashierName': cashierName,
    };
  }
}
