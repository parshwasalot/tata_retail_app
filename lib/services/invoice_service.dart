import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import 'product_service.dart';

class InvoiceService {
  final CollectionReference invoicesCollection = FirebaseFirestore.instance
      .collection('invoices');
  final ProductService _productService = ProductService();

  // Save a new invoice
  Future<String> saveInvoice(Invoice invoice) async {
    try {
      DocumentReference docRef = await invoicesCollection.add(invoice.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  // Get all invoices
  Stream<List<Invoice>> getInvoices() {
    return invoicesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Invoice> invoices = [];

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<InvoiceItem> items = await _getInvoiceItems(
              data['items'] as List,
            );

            invoices.add(Invoice.fromMap(data, doc.id, items));
          }

          return invoices;
        });
  }

  // Get a single invoice by ID
  Future<Invoice> getInvoiceById(String id) async {
    try {
      DocumentSnapshot doc = await invoicesCollection.doc(id).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<InvoiceItem> items = await _getInvoiceItems(data['items'] as List);

      return Invoice.fromMap(data, doc.id, items);
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  // Helper method to reconstruct invoice items from stored data
  Future<List<InvoiceItem>> _getInvoiceItems(List itemsData) async {
    List<InvoiceItem> items = [];

    for (var itemData in itemsData) {
      // Create product directly from stored data when possible
      if (itemData.containsKey('productName') &&
          itemData.containsKey('price') &&
          itemData.containsKey('gstRate')) {
        Product product = Product(
          id: itemData['productId'] ?? '',
          name: itemData['productName'],
          price:
              (itemData['price'] is int)
                  ? (itemData['price'] as int).toDouble()
                  : itemData['price'],
          gstRate: itemData['gstRate'],
        );

        items.add(
          InvoiceItem(product: product, quantity: itemData['quantity'] ?? 0),
        );
      } else {
        // Fallback to fetching from database if data is incomplete
        String productId = itemData['productId'];
        Product product = await _productService.getProductById(productId);
        items.add(
          InvoiceItem(product: product, quantity: itemData['quantity'] ?? 0),
        );
      }
    }

    return items;
  }

  // Get invoices for a specific date range
  Stream<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    Timestamp startTimestamp = Timestamp.fromDate(startDate);
    Timestamp endTimestamp = Timestamp.fromDate(endDate);

    return invoicesCollection
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Invoice> invoices = [];

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<InvoiceItem> items = await _getInvoiceItems(
              data['items'] as List,
            );

            invoices.add(Invoice.fromMap(data, doc.id, items));
          }

          return invoices;
        });
  }

  // Get invoices for a specific customer
  Stream<List<Invoice>> getInvoicesByCustomerId(String customerId) {
    return invoicesCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Invoice> invoices = [];

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<InvoiceItem> items = await _getInvoiceItems(
              data['items'] as List,
            );

            invoices.add(Invoice.fromMap(data, doc.id, items));
          }

          return invoices;
        });
  }

  // Search for invoices by customer name or invoice ID
  Stream<List<Invoice>> searchInvoices(
    String query, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Start with a base query
    Query baseQuery = invoicesCollection.orderBy('timestamp', descending: true);

    // Apply date filters if provided
    if (startDate != null) {
      Timestamp startTimestamp = Timestamp.fromDate(startDate);
      baseQuery = baseQuery.where(
        'timestamp',
        isGreaterThanOrEqualTo: startTimestamp,
      );
    }

    if (endDate != null) {
      Timestamp endTimestamp = Timestamp.fromDate(endDate);
      baseQuery = baseQuery.where(
        'timestamp',
        isLessThanOrEqualTo: endTimestamp,
      );
    }

    // We'll filter by customer name in memory since Firestore doesn't support OR conditions easily
    return baseQuery.snapshots().asyncMap((snapshot) async {
      List<Invoice> invoices = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Filter by customer name or invoice ID if query is provided
        if (query.isNotEmpty) {
          String customerName = (data['customerName'] as String).toLowerCase();
          String invoiceId = doc.id.toLowerCase();
          if (!customerName.contains(query.toLowerCase()) &&
              !invoiceId.contains(query.toLowerCase())) {
            continue; // Skip this invoice if it doesn't match the search
          }
        }

        List<InvoiceItem> items = await _getInvoiceItems(data['items'] as List);
        invoices.add(Invoice.fromMap(data, doc.id, items));
      }

      return invoices;
    });
  }
}
