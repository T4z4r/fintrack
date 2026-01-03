import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import 'core/database_helper.dart';
import 'dashboard/dashboard_screen.dart';
import 'income/income_screen.dart';
import 'expense/expense_screen.dart';
import 'asset/asset_screen.dart';
import 'debt/debt_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    IncomeScreen(),
    ExpenseScreen(),
    AssetScreen(),
    DebtScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FinTrack'),
        backgroundColor: Colors.grey[200],
        foregroundColor: Color(0xFF72140C),
        actions: [
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: () async {
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
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        shape: Border(
          left: BorderSide(
            color: Color(0xFF72140C),
            width: 4.0,
          ),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 🔴 IMPORTANT FIX
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_down),
            label: 'Expense',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Asset',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off),
            label: 'Debt',
          ),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF72140C), // Krismo / FinTrack color
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
