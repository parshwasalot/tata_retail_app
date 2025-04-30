import 'package:flutter/material.dart';
import '../services/authentication_service.dart';
import 'login_screen.dart';
import 'invoice_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthenticationService();
    final userName = authService.currentUser?.displayName ?? 'Cashier';
    final userEmail = authService.currentUser?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // User profile section with enhanced styling
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            margin: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(userEmail, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  'Cashier',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Help and Information Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'Help & Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // GST Calculation Help
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text('GST Calculation Guide'),
            subtitle: const Text('Learn how GST is calculated on products'),
            onTap: () {
              _showGstInfoDialog(context);
            },
          ),

          // GST Rates Help
          ListTile(
            leading: const Icon(Icons.percent, color: Colors.green),
            title: const Text('GST Rate Categories'),
            subtitle: const Text('Understand different GST slabs'),
            onTap: () {
              _showGstRatesDialog(context);
            },
          ),

          // Invoice Format Help
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.orange),
            title: const Text('Invoice Format Guide'),
            subtitle: const Text('Understand invoice components'),
            onTap: () {
              _showInvoiceFormatDialog(context);
            },
          ),

          const Divider(),

          // App Options
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'App Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text('Invoice History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvoiceHistoryScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // App Information
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'About App',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
          ),

          const Divider(),

          // Logout option with enhanced styling
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              onPressed: () async {
                // Show confirmation dialog
                final shouldLogout = await _showLogoutConfirmationDialog(
                  context,
                );
                if (shouldLogout == true) {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  void _showGstInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('GST Calculation Guide'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Goods and Services Tax (GST) in India is calculated as follows:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('GST Calculation Formula:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('• CGST = (Price × GST %) / 2'),
                        Text('• SGST = (Price × GST %) / 2'),
                        Text('• Total Price = Price + CGST + SGST'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Example Calculation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('For a product with:'),
                        Text('- Price: ₹100'),
                        Text('- GST Rate: 18%'),
                        SizedBox(height: 8),
                        Text('CGST = (100 × 18%) / 2 = ₹9'),
                        Text('SGST = (100 × 18%) / 2 = ₹9'),
                        Text('Total Price = ₹100 + ₹9 + ₹9 = ₹118'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showGstRatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('GST Rate Categories'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'India has a multi-tier GST structure with the following rates:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildGstRateCard(
                    '5%',
                    'Essential goods',
                    Colors.green.shade100,
                  ),
                  const SizedBox(height: 8),
                  _buildGstRateCard(
                    '12%',
                    'Standard goods',
                    Colors.blue.shade100,
                  ),
                  const SizedBox(height: 8),
                  _buildGstRateCard(
                    '18%',
                    'Standard services',
                    Colors.orange.shade100,
                  ),
                  const SizedBox(height: 8),
                  _buildGstRateCard('28%', 'Luxury items', Colors.red.shade100),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildGstRateCard(String rate, String category, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              rate,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'CGST: ${double.parse(rate.replaceAll('%', '')) / 2}%, SGST: ${double.parse(rate.replaceAll('%', '')) / 2}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Invoice Format Guide'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Components of a GST Invoice:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInvoiceComponentItem(
                    'Invoice Header',
                    'Contains business name, GST number, and invoice number',
                  ),
                  _buildInvoiceComponentItem(
                    'Customer Details',
                    'Name and contact information of the customer',
                  ),
                  _buildInvoiceComponentItem(
                    'Product List',
                    'List of items with quantity, rate, and amount',
                  ),
                  _buildInvoiceComponentItem(
                    'GST Breakdown',
                    'Shows CGST and SGST amounts for each item',
                  ),
                  _buildInvoiceComponentItem(
                    'Totals',
                    'Subtotal, tax totals, and grand total',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Legal Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('• Must show CGST and SGST separately'),
                        Text('• Requires a unique invoice number'),
                        Text('• Date of issue must be displayed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildInvoiceComponentItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
