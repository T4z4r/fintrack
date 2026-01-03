import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Api _api;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  // Helper method for creating styled metric cards
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : const Color(0xFFFBF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Get the API instance from AuthProvider
    _api = Provider.of<AuthProvider>(context, listen: false).api;
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final response = await _api.getDashboard();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        bool success = data['success'] ?? false;

        if (success) {
          setState(() {
            _dashboardData = data['data'];
            _isLoading = false;
          });
        } else {
          String message = data['message'] ?? 'Unknown error';
          setState(() {
            _dashboardData = null;
            _isLoading = false;
          });
          _showError('Failed to load dashboard: $message');
        }
      } else {
        setState(() {
          _dashboardData = null;
          _isLoading = false;
        });
        _showError('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _dashboardData = null;
        _isLoading = false;
      });
      _showError('Error loading dashboard: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : _dashboardData != null
            ? Padding(
                padding: EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Text(
                      'Welcome to FinTrack',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 24),
                    Text('Financial Summary',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.trending_up,
                            title: 'Total Income',
                            value:
                                '\$${_dashboardData!['financial_summary']?['total_income'] ?? 0}',
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.trending_down,
                            title: 'Total Expenses',
                            value:
                                '\$${_dashboardData!['financial_summary']?['total_expenses'] ?? 0}',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.account_balance_wallet,
                            title: 'Total Assets',
                            value:
                                '\$${_dashboardData!['financial_summary']?['total_assets'] ?? 0}',
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.credit_card,
                            title: 'Total Debts',
                            value:
                                '\$${_dashboardData!['financial_summary']?['total_debts'] ?? 0}',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildMetricCard(
                      icon: Icons.account_balance,
                      title: 'Net Worth',
                      value:
                          '\$${_dashboardData!['financial_summary']?['net_worth'] ?? 0}',
                      color: Colors.purple,
                    ),
                    SizedBox(height: 24),
                    Text('Calculated Metrics',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.savings,
                            title: 'Savings Rate',
                            value:
                                '${(_dashboardData!['calculated_metrics']?['savings_rate'] ?? 0).toStringAsFixed(2)}%',
                            color: Colors.teal,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.pie_chart,
                            title: 'Debt to Asset Ratio',
                            value:
                                '${(_dashboardData!['calculated_metrics']?['debt_to_asset_ratio'] ?? 0).toStringAsFixed(2)}%',
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildMetricCard(
                      icon: Icons.attach_money,
                      title: 'Total Savings',
                      value:
                          '\$${_dashboardData!['calculated_metrics']?['total_savings'] ?? 0}',
                      color: Colors.greenAccent,
                    ),
                    SizedBox(height: 24),
                    Text('Breakdown',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.business_center,
                            title: 'Income Sources',
                            value:
                                '${_dashboardData!['breakdown']?['income_sources_count'] ?? 0}',
                            color: Colors.lightGreen,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.shopping_cart,
                            title: 'Expenses',
                            value:
                                '${_dashboardData!['breakdown']?['expenses_count'] ?? 0}',
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.home,
                            title: 'Assets',
                            value:
                                '${_dashboardData!['breakdown']?['assets_count'] ?? 0}',
                            color: Colors.blueAccent,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.money_off,
                            title: 'Debts',
                            value:
                                '${_dashboardData!['breakdown']?['debts_count'] ?? 0}',
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Center(child: Text('Failed to load dashboard'));
  }
}
