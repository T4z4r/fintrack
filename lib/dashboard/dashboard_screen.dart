import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api.dart';
import '../widgets/app_drawer.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dashboardData != null
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to FinTrack',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 24),
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
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance,
                                  size: 48, color: Colors.blue),
                              SizedBox(height: 8),
                              Text('Net Worth', style: TextStyle(fontSize: 16)),
                              Text(
                                '\$${_dashboardData!['financial_summary']?['net_worth'] ?? 0}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: Text('Failed to load dashboard')),
    );
  }
}
