import 'package:flutter/material.dart';
import '../core/database_helper.dart';
import '../core/api.dart';

class DebtScreen extends StatefulWidget {
  @override
  _DebtScreenState createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final Api _api = Api();
  List<Map<String, dynamic>> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDebts();
    _syncDebts();
  }

  Future<void> _fetchDebts() async {
    try {
      _debts = await _db.getDebts();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncDebts() async {
    await _api.syncDebts();
  }

  Future<void> _addDebt() async {
    await _db.insertDebt({
      'name': 'Test Debt',
      'amount': 5000.0,
      'due_date': '2025-01-01',
      'status': 'pending',
      'synced': 0,
    });
    _fetchDebts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debt')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _debts.length,
              itemBuilder: (context, index) {
                final debt = _debts[index];
                return ListTile(
                  title: Text(debt['name'] ?? 'No name'),
                  subtitle: Text('Amount: ${debt['amount']}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        child: Icon(Icons.add),
      ),
    );
  }
}