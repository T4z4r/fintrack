import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api.dart';

class DebtScreen extends StatefulWidget {
  @override
  _DebtScreenState createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final Api _api = Api();
  List<dynamic> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    try {
      final response = await _api.getDebts();
      if (response.statusCode == 200) {
        setState(() {
          _debts = json.decode(response.body)['data'] ?? [];
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
        onPressed: () {
          // Add debt
        },
        child: Icon(Icons.add),
      ),
    );
  }
}