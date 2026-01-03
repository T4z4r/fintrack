import 'package:flutter/material.dart';
import '../core/database_helper.dart';
import '../core/api.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final Api _api = Api();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _syncExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      _expenses = await _db.getExpenses();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncExpenses() async {
    await _api.syncExpenses();
  }

  Future<void> _addExpense() async {
    await _db.insertExpense({
      'amount': 100.0,
      'category': 'food',
      'date': '2024-01-01',
      'description': 'Test Expense',
      'synced': 0,
    });
    _fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              return ListTile(
                title: Text(expense['description'] ?? 'No description'),
                subtitle: Text('Amount: ${expense['amount']}'),
              );
            },
          );
  }
}
