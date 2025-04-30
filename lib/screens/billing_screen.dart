import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../services/product_service.dart';
import '../services/invoice_service.dart';
import '../services/authentication_service.dart';
import '../screens/invoice_details_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final ProductService _productService = ProductService();
  final InvoiceService _invoiceService = InvoiceService();
  final AuthenticationService _authService = AuthenticationService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();

  List<InvoiceItem> _cartItems = [];
  List<Product> _searchResults = [];
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  // Search for products with improved error handling and debounce
  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _productService.searchProductsSync(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add product to cart with improved animation
  void _addToCart(Product product) {
    setState(() {
      // Check if product is already in cart
      int existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        // Increment quantity if product already exists
        _cartItems[existingIndex] = InvoiceItem(
          product: product,
          quantity: _cartItems[existingIndex].quantity + 1,
        );

        // Show a subtle animation or highlight to indicate product was added
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} quantity increased'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add new item with quantity 1
        _cartItems.add(InvoiceItem(product: product, quantity: 1));

        // Show a subtle animation or highlight to indicate product was added
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear search
      _searchController.clear();
      _searchResults = [];
      _searchQuery = '';
    });
  }

  // Update item quantity with immediate UI update
  void _updateQuantity(int index, int quantity) {
    if (index < 0 || index >= _cartItems.length) return;

    final product = _cartItems[index].product;
    final oldQuantity = _cartItems[index].quantity;

    setState(() {
      if (quantity <= 0) {
        // Remove item if quantity is zero or negative
        _cartItems.removeAt(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} removed from cart'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Update quantity
        _cartItems[index] = InvoiceItem(product: product, quantity: quantity);

        if (quantity > oldQuantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} quantity increased to $quantity'),
              duration: const Duration(milliseconds: 500),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} quantity decreased to $quantity'),
              duration: const Duration(milliseconds: 500),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    });
  }

  // Calculate totals with better precision
  double _calculateSubtotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.calculateItemPrice());
  }

  double _calculateTotalCGST() {
    return _cartItems.fold(0, (sum, item) => sum + item.calculateCGST());
  }

  double _calculateTotalSGST() {
    return _cartItems.fold(0, (sum, item) => sum + item.calculateSGST());
  }

  double _calculateGrandTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.calculateTotalPrice());
  }

  // Clear cart with confirmation
  void _clearCart() {
    if (_cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text('Are you sure you want to clear the cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _cartItems = [];
                    _customerNameController.clear();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cart cleared'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  // Create and save invoice to Firestore
  Future<String?> _saveInvoice() async {
    if (_cartItems.isEmpty) return null;

    try {
      // Generate a temporary ID (will be replaced by Firestore)
      String tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

      // Get current cashier name
      String cashierName =
          _authService.currentUser?.displayName ?? 'Unknown Cashier';

      // Create invoice object
      Invoice invoice = Invoice(
        id: tempId,
        customerId: '',
        customerName:
            _customerNameController.text.isEmpty
                ? 'Walk-in Customer'
                : _customerNameController.text,
        items: List.from(_cartItems),
        timestamp: DateTime.now(),
        cashierName: cashierName,
      );

      // Save to Firestore
      String invoiceId = await _invoiceService.saveInvoice(invoice);
      return invoiceId;
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  // Generate invoice with success dialog
  void _generateInvoice() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add items to generate invoice.'),
        ),
      );
      return;
    }

    // Show dialog to confirm invoice generation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Generate Invoice'),
            content: const Text(
              'Do you want to generate an invoice for the current items?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Close the confirmation dialog
                  Navigator.of(context).pop();

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  try {
                    // Save invoice and get ID
                    final invoiceId = await _saveInvoice();

                    // Close loading indicator
                    if (context.mounted) Navigator.of(context).pop();

                    if (invoiceId != null && context.mounted) {
                      // Show success dialog with options
                      _showInvoiceSuccessDialog(invoiceId);
                    }
                  } catch (e) {
                    // Close loading indicator
                    if (context.mounted) Navigator.of(context).pop();

                    // Show error
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error generating invoice: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Generate'),
              ),
            ],
          ),
    );
  }

  // Show success dialog with options
  void _showInvoiceSuccessDialog(String invoiceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Invoice Generated'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice #$invoiceId has been successfully created.'),
              SizedBox(height: 10),
              Text(
                'Total Amount: ₹${_calculateGrandTotal().toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear cart and close dialog
                setState(() {
                  _cartItems = [];
                  _customerNameController.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ready for new bill'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('New Bill'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close dialog
                Navigator.of(context).pop();

                // Navigate to invoice details
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                InvoiceDetailsScreen(invoiceId: invoiceId),
                      ),
                    )
                    .then((_) {
                      // Clear cart when returning
                      setState(() {
                        _cartItems = [];
                        _customerNameController.clear();
                      });
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Cart',
            onPressed: _clearCart,
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer name input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),

          // Product search with improved UX
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                        : null,
                hintText: 'Type to search products...',
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Add a slight delay to prevent excessive API calls
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (value == _searchQuery) {
                    _searchProducts(value);
                  }
                });
              },
            ),
          ),

          // Search results with improved display
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child:
                  _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            child: ListTile(
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Price: ₹${product.price.toStringAsFixed(2)} | GST: ${product.gstRate}%',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${product.calculateTotalPrice().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _addToCart(product),
                                    tooltip: 'Add to cart',
                                  ),
                                ],
                              ),
                              onTap: () => _addToCart(product),
                            ),
                          );
                        },
                      ),
            ),

          // Cart items with improved display
          Expanded(
            child:
                _cartItems.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Search and add products above',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        final product = item.product;

                        return Card(
                          margin: const EdgeInsets.all(4.0),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Product info
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Text(' × '),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '₹${item.calculateItemPrice().toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'GST: ${product.gstRate}%',
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'CGST: ₹${item.calculateCGST().toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'SGST: ₹${item.calculateSGST().toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          Text(
                                            'Total: ₹${item.calculateTotalPrice().toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity controls
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        _updateQuantity(
                                          index,
                                          item.quantity + 1,
                                        );
                                      },
                                      tooltip: 'Increase quantity',
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () {
                                        _updateQuantity(
                                          index,
                                          item.quantity - 1,
                                        );
                                      },
                                      tooltip: 'Decrease quantity',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _updateQuantity(
                                          index,
                                          0,
                                        ); // Remove item
                                      },
                                      tooltip: 'Remove item',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Totals summary with improved display
          if (_cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('₹${_calculateSubtotal().toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CGST:'),
                      Text('₹${_calculateTotalCGST().toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SGST:'),
                      Text('₹${_calculateTotalSGST().toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '₹${_calculateGrandTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _cartItems.isEmpty ? null : _generateInvoice,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            backgroundColor: Colors.green,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Generate Invoice (${_cartItems.length} ${_cartItems.length == 1 ? 'item' : 'items'})',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
