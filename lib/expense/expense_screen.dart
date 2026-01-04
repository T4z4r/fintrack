import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/bottom_sheet_form.dart';
import '../widgets/date_picker_field.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late Api _api;
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  // Form controllers for bottom sheet
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentSourceController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Get the API instance from AuthProvider
    _api = Provider.of<AuthProvider>(context, listen: false).api;
    _fetchExpenses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _paymentSourceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExpenses() async {
    try {
      final response = await _api.getExpenses();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _expenses = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addExpense() async {
    // Clear form
    _amountController.clear();
    _categoryController.clear();
    _dateController.clear();
    _notesController.clear();
    _paymentSourceController.clear();

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Expense',
      formKey: _formKey,
      formFields: [
        _buildAmountField(),
        SizedBox(height: 16),
        _buildCategoryField(),
        SizedBox(height: 16),
        _buildPaymentSourceField(),
        SizedBox(height: 16),
        _buildDateField(),
        SizedBox(height: 16),
        _buildNotesField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'amount': double.parse(_amountController.text),
          'category': _categoryController.text,
          'date': _dateController.text,
          'notes': _notesController.text,
          'payment_source': _paymentSourceController.text,
        });
      },
      submitText: 'Add Expense',
    );

    if (result != null) {
      try {
        final response = await _api.createExpense(result);
        if (response.statusCode == 201) {
          _fetchExpenses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Expense created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create expense')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final response = await _api.deleteExpense(id);
        if (response.statusCode == 200) {
          _fetchExpenses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Expense deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete expense')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter amount';
        }
        if (double.tryParse(value!) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter category';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return DatePickerField(
      labelText: 'Date',
      hintText: 'YYYY-MM-DD',
      controller: _dateController,
      prefixIcon: Icons.calendar_today,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentSourceField() {
    return TextFormField(
      controller: _paymentSourceController,
      decoration: InputDecoration(
        labelText: 'Payment Source',
        prefixIcon: Icon(Icons.account_balance_wallet),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter payment source';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notes',
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      final description = (expense['description'] ?? '').toLowerCase();
      final category = (expense['category'] ?? '').toLowerCase();
      final paymentSource = (expense['payment_source'] ?? '').toLowerCase();
      return description.contains(query) ||
          category.contains(query) ||
          paymentSource.contains(query);
    }).toList();

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF72140C),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading expenses...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_down_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No expenses found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first expense to start tracking',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search expenses',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchExpenses,
                        color: Color(0xFF72140C),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            final amount = double.tryParse(
                                    expense['amount']?.toString() ?? '0') ??
                                0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 10),
                              color: Theme.of(context).cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.trending_down,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(expense['description'] ??
                                      'No description'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${expense['date'] ?? 'N/A'} • ${expense['category'] ?? 'N/A'} • ${expense['payment_source'] ?? 'N/A'}'),
                                      Text('\$${amount.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteExpense(expense['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete,
                                              color: Colors.red),
                                          title: Text('Delete'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: Color(0xFF72140C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Expense',
      ),
    );
  }
}
