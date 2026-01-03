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
        setState(() {
          _dashboardData = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
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
                          'Total Income: ${_dashboardData!['total_income'] ?? 0}'),
                      Text(
                          'Total Expenses: ${_dashboardData!['total_expenses'] ?? 0}'),
                      Text('Net Worth: ${_dashboardData!['net_worth'] ?? 0}'),
                      // Add more fields as per API response
                    ],
                  ),
                )
              : Center(child: Text('Failed to load dashboard')),
    );
  }
}
