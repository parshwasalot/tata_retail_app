import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../services/invoice_service.dart';
import 'package:intl/intl.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  bool _isLoading = true;
  Invoice? _invoice;
  String? _errorMessage;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final invoice = await _invoiceService.getInvoiceById(widget.invoiceId);
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load invoice: $e';
        _isLoading = false;
      });
    }
  }

  // Generate and share invoice as text
  void _shareInvoice() async {
    if (_invoice == null) return;

    try {
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

      // Build invoice text content
      final StringBuffer content = StringBuffer();
      content.writeln('TATA RETAIL SOLUTIONS GST INVOICE');
      content.writeln('-----------------------------');
      content.writeln('Invoice #: ${widget.invoiceId}');
      content.writeln('Date: ${dateFormat.format(_invoice!.timestamp)}');
      content.writeln('Cashier: ${_invoice!.cashierName}');
      content.writeln('Customer: ${_invoice!.customerName}');
      content.writeln('-----------------------------');
      content.writeln('ITEMS:');

      for (var item in _invoice!.items) {
        content.writeln('${item.product.name} × ${item.quantity}');
        content.writeln(
          '  Price: ₹${item.product.price.toStringAsFixed(2)} each',
        );
        content.writeln('  GST: ${item.product.gstRate}%');
        content.writeln('  CGST: ₹${item.calculateCGST().toStringAsFixed(2)}');
        content.writeln('  SGST: ₹${item.calculateSGST().toStringAsFixed(2)}');
        content.writeln(
          '  Item Total: ₹${item.calculateTotalPrice().toStringAsFixed(2)}',
        );
        content.writeln('-----------------------------');
      }

      content.writeln('SUMMARY:');
      content.writeln(
        'Subtotal: ₹${_invoice!.calculateSubtotal().toStringAsFixed(2)}',
      );
      content.writeln(
        'CGST: ₹${_invoice!.calculateTotalCGST().toStringAsFixed(2)}',
      );
      content.writeln(
        'SGST: ₹${_invoice!.calculateTotalSGST().toStringAsFixed(2)}',
      );
      content.writeln(
        'Grand Total: ₹${_invoice!.calculateGrandTotal().toStringAsFixed(2)}',
      );
      content.writeln('-----------------------------');
      content.writeln('Thank you for shopping with TATA Retail Solutions!');

      // Share the text content
      await Share.share(
        content.toString(),
        subject: 'Invoice #${widget.invoiceId}',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing invoice: $e')));
    }
  }

  // Generate PDF invoice
  Future<void> _generateAndDownloadPdf() async {
    if (_invoice == null) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TATA Retail Solutions',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      'GST INVOICE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text(
                      'Invoice #: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(widget.invoiceId),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Date: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(dateFormat.format(_invoice!.timestamp)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Cashier: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(_invoice!.cashierName),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Customer: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(_invoice!.customerName),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Items',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfItemsTable(),
                pw.SizedBox(height: 20),
                _buildPdfTotals(),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: pw.Text(
                    'Thank you for shopping with TATA Retail Solutions!',
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated invoice. No signature required.',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to a file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${widget.invoiceId}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isGeneratingPdf = false;
      });

      // Share the PDF file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Invoice #${widget.invoiceId}');
    } catch (e) {
      setState(() {
        _isGeneratingPdf = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  // Build PDF table for items
  pw.Widget _buildPdfItemsTable() {
    final headers = ['Product', 'Qty', 'Rate', 'GST%', 'Amount'];
    final data =
        _invoice!.items.map((item) {
          return [
            item.product.name,
            item.quantity.toString(),
            '₹${item.product.price.toStringAsFixed(2)}',
            '${item.product.gstRate}%',
            '₹${item.calculateItemPrice().toStringAsFixed(2)}',
          ];
        }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  // Build PDF totals section
  pw.Widget _buildPdfTotals() {
    return pw.Column(
      children: [
        _buildPdfTotalRow(
          'Subtotal:',
          '₹${_invoice!.calculateSubtotal().toStringAsFixed(2)}',
        ),
        _buildPdfTotalRow(
          'CGST:',
          '₹${_invoice!.calculateTotalCGST().toStringAsFixed(2)}',
        ),
        _buildPdfTotalRow(
          'SGST:',
          '₹${_invoice!.calculateTotalSGST().toStringAsFixed(2)}',
        ),
        pw.Divider(),
        _buildPdfTotalRow(
          'Grand Total:',
          '₹${_invoice!.calculateGrandTotal().toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  // Helper for PDF total rows
  pw.Widget _buildPdfTotalRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  // Print invoice (placeholder functionality)
  void _printInvoice() {
    // In a real app, this could connect to a printer via platform channels
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Invoice printing will be implemented in a future update',
        ),
      ),
    );
  }

  // Copy invoice ID to clipboard
  void _copyInvoiceId() {
    Clipboard.setData(ClipboardData(text: widget.invoiceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice ID copied to clipboard')),
    );
  }

  // Share invoice via various methods
  void _showShareOptions() {
    if (_invoice == null) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Share as Text'),
                onTap: () {
                  Navigator.pop(context);
                  _shareInvoice();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generate PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndDownloadPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print Invoice'),
                onTap: () {
                  Navigator.pop(context);
                  _printInvoice();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _invoice != null ? _showShareOptions : null,
            tooltip: 'Share Invoice',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isGeneratingPdf)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Generating PDF...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadInvoice, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_invoice == null) {
      return const Center(child: Text('No invoice data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(),
          const Divider(thickness: 2),
          _buildItemsTable(),
          const Divider(thickness: 2),
          _buildTotals(),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TATA Retail Solutions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'GST Invoice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'Invoice #: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.invoiceId),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: _copyInvoiceId,
              tooltip: 'Copy Invoice ID',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(dateFormat.format(_invoice!.timestamp)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text(
              'Cashier: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_invoice!.cashierName),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text(
              'Customer: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_invoice!.customerName),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          color: Colors.grey.shade200,
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Product',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Rate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'GST%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Table rows
        ..._invoice!.items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildItemRow(InvoiceItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text('${item.quantity}', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '₹${item.product.price.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${item.product.gstRate}%',
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '₹${item.calculateItemPrice().toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'CGST: ₹${item.calculateCGST().toStringAsFixed(2)} | SGST: ₹${item.calculateSGST().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', _invoice!.calculateSubtotal()),
          const SizedBox(height: 4),
          _buildTotalRow('CGST:', _invoice!.calculateTotalCGST()),
          const SizedBox(height: 4),
          _buildTotalRow('SGST:', _invoice!.calculateTotalSGST()),
          const Divider(),
          _buildTotalRow(
            'Grand Total:',
            _invoice!.calculateGrandTotal(),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _shareInvoice,
          icon: const Icon(Icons.share),
          label: const Text('Share'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _printInvoice,
          icon: const Icon(Icons.print),
          label: const Text('Print'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}
