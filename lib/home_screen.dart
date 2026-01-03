import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'income/income_screen.dart';
import 'expense/expense_screen.dart';
import 'asset/asset_screen.dart';
import 'debt/debt_screen.dart';
import 'budget/budget_screen.dart';
import 'investment/investment_screen.dart';

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
    CombinedAssetsDebtsScreen(),
    CombinedBudgetInvestmentScreen(),
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
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.white),
            SizedBox(width: 8),
            Text('FinTrack'),
          ],
        ),
        backgroundColor: Color(0xFF72140C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh current screen
              setState(() {
                _selectedIndex = _selectedIndex;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data refreshed')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              activeIcon: Icon(Icons.trending_up),
              label: 'Income',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_down),
              activeIcon: Icon(Icons.trending_down),
              label: 'Expense',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance),
              activeIcon: Icon(Icons.account_balance),
              label: 'Assets & Debts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Budget & Invest',
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF72140C),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
          onTap: _onItemTapped,
          elevation: 8,
        ),
      ),
    );
  }
}

// Combined screen for Assets and Debts
class CombinedAssetsDebtsScreen extends StatefulWidget {
  @override
  _CombinedAssetsDebtsScreenState createState() => _CombinedAssetsDebtsScreenState();
}

class _CombinedAssetsDebtsScreenState extends State<CombinedAssetsDebtsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? Color(0xFF72140C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: _selectedTab == 0 ? Colors.white : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Assets',
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? Color(0xFF72140C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off,
                          color: _selectedTab == 1 ? Colors.white : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Debts',
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == 0 ? AssetScreen() : DebtScreen(),
        ),
      ],
    );
  }
}

// Combined screen for Budget and Investment
class CombinedBudgetInvestmentScreen extends StatefulWidget {
  @override
  _CombinedBudgetInvestmentScreenState createState() => _CombinedBudgetInvestmentScreenState();
}

class _CombinedBudgetInvestmentScreenState extends State<CombinedBudgetInvestmentScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? Color(0xFF72140C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          color: _selectedTab == 0 ? Colors.white : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Budgets',
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? Color(0xFF72140C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          color: _selectedTab == 1 ? Colors.white : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Investments',
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == 0 ? BudgetScreen() : InvestmentScreen(),
        ),
      ],
    );
  }
}
