import 'package:flutter/material.dart';
import '../core/database_helper.dart';
import '../core/api.dart';

class IncomeScreen extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final Api _api = Api();
  List<Map<String, dynamic>> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncomes();
    _syncIncomes();
  }

  Future<void> _fetchIncomes() async {
    try {
      _incomes = await _db.getIncomes();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncIncomes() async {
    await _api.syncIncomes();
  }

  Future<void> _addIncome() async {
    // Simple add for demo
    await _db.insertIncome({
      'amount': 1000.0,
      'date': '2024-01-01',
      'description': 'Test Income',
      'synced': 0,
    });
    _fetchIncomes();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _incomes.length,
            itemBuilder: (context, index) {
              final income = _incomes[index];
              return ListTile(
                title: Text(income['description'] ?? 'No description'),
                subtitle: Text('Amount: ${income['amount']}'),
              );
            },
          );
  }
}
