import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final Api _api = Api();
  List<dynamic> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      final response = await _api.getExpenses();
      if (response.statusCode == 200) {
        setState(() {
          _expenses = json.decode(response.body)['data'] ?? [];
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
      appBar: AppBar(title: Text('Expense')),
      body: _isLoading
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add expense
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
