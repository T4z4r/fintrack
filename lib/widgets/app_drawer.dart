import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text('FinTrack'),
          ),
          ListTile(
            title: Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          ListTile(
            title: Text('Income'),
            onTap: () => Navigator.pushNamed(context, '/income'),
          ),
          ListTile(
            title: Text('Expense'),
            onTap: () => Navigator.pushNamed(context, '/expense'),
          ),
          ListTile(
            title: Text('Asset'),
            onTap: () => Navigator.pushNamed(context, '/asset'),
          ),
          ListTile(
            title: Text('Debt'),
            onTap: () => Navigator.pushNamed(context, '/debt'),
          ),
        ],
      ),
    );
  }
}