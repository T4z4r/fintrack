import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      drawer: Drawer(), // Will use AppDrawer later
      body: Center(
        child: Text('Welcome to FinTrack Dashboard'),
      ),
    );
  }
}