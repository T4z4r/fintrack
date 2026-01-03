import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Api _api = Api();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final response = await _api.getDashboard();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool success = data['success'] ?? true;
        if (success) {
          setState(() {
            _dashboardData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _dashboardData = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _dashboardData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _dashboardData = null;
        _isLoading = false;
      });
    }
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
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.trending_up,
                                      size: 48, color: Colors.green),
                                  SizedBox(height: 8),
                                  Text('Total Income',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '\$${_dashboardData!['financial_summary']?['total_income'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.trending_down,
                                      size: 48, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('Total Expenses',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '\$${_dashboardData!['financial_summary']?['total_expenses'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      size: 48, color: Colors.blue),
                                  SizedBox(height: 8),
                                  Text('Total Assets',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '\$${_dashboardData!['financial_summary']?['total_assets'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.credit_card,
                                      size: 48, color: Colors.orange),
                                  SizedBox(height: 8),
                                  Text('Total Debts',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '\$${_dashboardData!['financial_summary']?['total_debts'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.account_balance,
                                size: 48, color: Colors.purple),
                            SizedBox(height: 8),
                            Text('Net Worth', style: TextStyle(fontSize: 16)),
                            Text(
                              '\$${_dashboardData!['financial_summary']?['net_worth'] ?? 0}',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text('Calculated Metrics',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.savings,
                                      size: 48, color: Colors.teal),
                                  SizedBox(height: 8),
                                  Text('Savings Rate',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '${(_dashboardData!['calculated_metrics']?['savings_rate'] ?? 0).toStringAsFixed(2)}%',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.pie_chart,
                                      size: 48, color: Colors.indigo),
                                  SizedBox(height: 8),
                                  Text('Debt to Asset Ratio',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '${(_dashboardData!['calculated_metrics']?['debt_to_asset_ratio'] ?? 0).toStringAsFixed(2)}%',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.attach_money,
                                size: 48, color: Colors.greenAccent),
                            SizedBox(height: 8),
                            Text('Total Savings',
                                style: TextStyle(fontSize: 16)),
                            Text(
                              '\$${_dashboardData!['calculated_metrics']?['total_savings'] ?? 0}',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text('Breakdown',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.business_center,
                                      size: 48, color: Colors.lightGreen),
                                  SizedBox(height: 8),
                                  Text('Income Sources',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '${_dashboardData!['breakdown']?['income_sources_count'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.lightGreen),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_cart,
                                      size: 48, color: Colors.redAccent),
                                  SizedBox(height: 8),
                                  Text('Expenses',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '${_dashboardData!['breakdown']?['expenses_count'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.home,
                                      size: 48, color: Colors.blueAccent),
                                  SizedBox(height: 8),
                                  Text('Assets',
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    '${_dashboardData!['breakdown']?['assets_count'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.money_off,
                                      size: 48, color: Colors.deepOrange),
                                  SizedBox(height: 8),
                                  Text('Debts', style: TextStyle(fontSize: 16)),
                                  Text(
                                    '${_dashboardData!['breakdown']?['debts_count'] ?? 0}',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange),
                                  ),
                                ],
                              ),
                            ),
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
