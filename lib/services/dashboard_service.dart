import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InvoiceService _invoiceService = InvoiceService();

  // Get today's invoices
  Stream<List<Invoice>> getTodaysInvoices() {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final endOfToday = startOfToday.add(const Duration(days: 1));

    return _firestore
        .collection('invoices')
        .where('timestamp', isGreaterThanOrEqualTo: startOfToday)
        .where('timestamp', isLessThan: endOfToday)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Invoice> invoices = [];

          for (var doc in snapshot.docs) {
            try {
              final invoice = await _invoiceService.getInvoiceById(doc.id);
              invoices.add(invoice);
            } catch (e) {
              print('Error loading invoice ${doc.id}: $e');
            }
          }

          return invoices;
        });
  }

  // Get today's sales total
  Future<double> getTodaySalesTotal() async {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final endOfToday = startOfToday.add(const Duration(days: 1));

    final snapshot =
        await _firestore
            .collection('invoices')
            .where('timestamp', isGreaterThanOrEqualTo: startOfToday)
            .where('timestamp', isLessThan: endOfToday)
            .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      try {
        final invoice = await _invoiceService.getInvoiceById(doc.id);
        total += invoice.calculateGrandTotal();
      } catch (e) {
        print('Error calculating total for invoice ${doc.id}: $e');
      }
    }

    return total;
  }

  // Get today's transaction count
  Future<int> getTodayTransactionCount() async {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final endOfToday = startOfToday.add(const Duration(days: 1));

    final snapshot =
        await _firestore
            .collection('invoices')
            .where('timestamp', isGreaterThanOrEqualTo: startOfToday)
            .where('timestamp', isLessThan: endOfToday)
            .get();

    return snapshot.docs.length;
  }

  // Get average transaction value
  Future<double> getAverageTransactionValue() async {
    final total = await getTodaySalesTotal();
    final count = await getTodayTransactionCount();

    if (count == 0) {
      return 0;
    }

    return total / count;
  }
}
