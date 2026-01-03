import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api.dart';

class IncomeScreen extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final Api _api = Api();
  List<dynamic> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncomes();
  }

  Future<void> _fetchIncomes() async {
    try {
      final response = await _api.getIncomes();
      if (response.statusCode == 200) {
        setState(() {
          _incomes = json.decode(response.body)['data'] ?? [];
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
      appBar: AppBar(title: Text('Income')),
      body: _isLoading
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add income screen or show dialog
        },
        child: Icon(Icons.add),
      ),
    );
  }
}