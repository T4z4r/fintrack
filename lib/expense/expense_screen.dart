import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/bottom_sheet_form.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/custom_loader.dart';

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
      header: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFF72140C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.add_box,
          size: 40,
          color: Color(0xFF72140C),
        ),
      ),
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

  Future<void> _viewExpenseDetails(Map<String, dynamic> expense) async {
    final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.only(top: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.trending_down,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete information about this expense',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Amount highlight
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.red,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Details
                    _buildDetailSection('Expense Information', [
                      _buildDetailRow(
                          'Notes', expense['notes'] ?? 'N/A', Icons.notes),
                      _buildDetailRow('Category', expense['category'] ?? 'N/A',
                          Icons.category),
                      _buildDetailRow(
                          'Payment Source',
                          expense['payment_source'] ?? 'N/A',
                          Icons.account_balance_wallet),
                      _buildDetailRow('Date', expense['date'] ?? 'N/A',
                          Icons.calendar_today),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created', expense['created_at'] ?? 'N/A',
                          Icons.access_time),
                      _buildDetailRow('Updated', expense['updated_at'] ?? 'N/A',
                          Icons.update),
                    ]),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.red,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Future<void> _editExpense(int id) async {
    try {
      final response = await _api.getExpense(id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final expense = data['data'];
          // Pre-fill controllers
          _amountController.text = expense['amount']?.toString() ?? '';
          _categoryController.text = expense['category'] ?? '';
          _dateController.text = expense['date'] ?? '';
          _notesController.text = expense['notes'] ?? '';
          _paymentSourceController.text = expense['payment_source'] ?? '';

          final result = await BottomSheetForm.show<Map<String, dynamic>>(
            context: context,
            title: 'Edit Expense',
            header: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.edit,
                size: 40,
                color: Colors.red,
              ),
            ),
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
            submitText: 'Update Expense',
          );

          if (result != null) {
            final updateResponse = await _api.updateExpense(id, result);
            if (updateResponse.statusCode == 200) {
              _fetchExpenses();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Expense updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update expense')),
              );
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
      final notes = (expense['notes'] ?? '').toLowerCase();
      final category = (expense['category'] ?? '').toLowerCase();
      final paymentSource = (expense['payment_source'] ?? '').toLowerCase();
      return notes.contains(query) ||
          category.contains(query) ||
          paymentSource.contains(query);
    }).toList();

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomLoader(
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
                      padding: EdgeInsets.all(8),
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
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            final amount = double.tryParse(
                                    expense['amount']?.toString() ?? '0') ??
                                0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 2),
                              color: Colors.white,
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
                                  title: Text(expense['notes'] ?? 'No notes'),
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
                                      if (value == 'view') {
                                        _viewExpenseDetails(expense);
                                      } else if (value == 'edit') {
                                        _editExpense(expense['id']);
                                      } else if (value == 'delete') {
                                        _deleteExpense(expense['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: ListTile(
                                          leading: Icon(Icons.visibility,
                                              color: Colors.blue),
                                          title: Text('View Details'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit,
                                              color: Colors.orange),
                                          title: Text('Edit'),
                                        ),
                                      ),
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
