import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../core/database_helper.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF72140C)),
            child: Text('FinTrack',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: Icon(Icons.trending_up),
            title: Text('Income'),
            onTap: () => Navigator.pushNamed(context, '/income'),
          ),
          ListTile(
            leading: Icon(Icons.trending_down),
            title: Text('Expense'),
            onTap: () => Navigator.pushNamed(context, '/expense'),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet),
            title: Text('Asset'),
            onTap: () => Navigator.pushNamed(context, '/asset'),
          ),
          ListTile(
            leading: Icon(Icons.money_off),
            title: Text('Debt'),
            onTap: () => Navigator.pushNamed(context, '/debt'),
          ),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('Recreate Database'),
            onTap: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Recreate Database'),
                    content: Text(
                        'This will delete all local data and recreate the database. Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Recreate'),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await DatabaseHelper().recreateDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Database recreated')),
                );
              }
            },
          ),
          Divider(),
          ListTile(
            title: Text('Logout'),
            onTap: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
