import 'package:flutter/material.dart';
import '../services/authentication_service.dart';
import '../services/dashboard_service.dart';
import 'login_screen.dart';
import 'product_management_screen.dart';
import 'invoice_history_screen.dart';
import 'billing_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthenticationService();
  final dashboardService = DashboardService();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  bool _isLoadingStats = true;
  double _todaySalesTotal = 0;
  int _todayTransactionCount = 0;
  double _averageTransactionValue = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final total = await dashboardService.getTodaySalesTotal();
      final count = await dashboardService.getTodayTransactionCount();
      final avg = await dashboardService.getAverageTransactionValue();

      if (mounted) {
        setState(() {
          _todaySalesTotal = total;
          _todayTransactionCount = count;
          _averageTransactionValue = avg;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = authService.currentUser?.displayName ?? 'Cashier';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TATA Retail Solutions'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Statistics',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Text(
                  'Welcome, $userName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today: ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Daily Statistics Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Statistics",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _isLoadingStats
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.show_chart,
                                  color: Colors.blue,
                                ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Statistics grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatisticItem(
                                'Total Sales',
                                _isLoadingStats
                                    ? '...'
                                    : currencyFormat.format(_todaySalesTotal),
                                Icons.payments,
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildStatisticItem(
                                'Transactions',
                                _isLoadingStats
                                    ? '...'
                                    : _todayTransactionCount.toString(),
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatisticItem(
                                'Avg. Value',
                                _isLoadingStats
                                    ? '...'
                                    : currencyFormat.format(
                                      _averageTransactionValue,
                                    ),
                                Icons.analytics,
                                Colors.purple,
                              ),
                            ),
                            const Expanded(
                              child:
                                  SizedBox(), // Empty space for layout balance
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent transactions section can be added here
                const SizedBox(height: 24),

                // Quick actions section
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.receipt,
                        label: 'New Bill',
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BillingScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.add_shopping_cart,
                        label: 'Add Product',
                        color: Colors.green,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ProductManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.history,
                        label: 'Invoice History',
                        color: Colors.orange,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const InvoiceHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.inventory,
                        label: 'Manage Inventory',
                        color: Colors.purple,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ProductManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
