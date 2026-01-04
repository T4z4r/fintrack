import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/bottom_sheet_form.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/custom_loader.dart';

class IncomeScreen extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late Api _api;
  List<Map<String, dynamic>> _incomes = [];
  List<Map<String, dynamic>> _incomeSources = [];
  bool _isLoading = true;

  // Form controllers for bottom sheet
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _incomeSourceId;

  @override
  void initState() {
    super.initState();
    // Get the API instance from AuthProvider
    _api = Provider.of<AuthProvider>(context, listen: false).api;
    _fetchData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchIncomes(),
      _fetchIncomeSources(),
    ]);
  }

  Future<void> _fetchIncomeSources() async {
    try {
      final response = await _api.getIncomeSources();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _incomeSources = List<Map<String, dynamic>>.from(data['data']);
            // Set default income source if available
            if (_incomeSources.isNotEmpty && _incomeSourceId == null) {
              _incomeSourceId = _incomeSources.first['id'] as String;
            }
          });
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _fetchIncomes() async {
    try {
      final response = await _api.getIncomes();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _incomes = List<Map<String, dynamic>>.from(data['data']);
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

  Future<void> _addIncome() async {
    // Clear form
    _amountController.clear();
    _dateController.clear();
    _notesController.clear();

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Income',
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
        _buildIncomeSourceDropdown(),
        SizedBox(height: 16),
        _buildAmountField(),
        SizedBox(height: 16),
        _buildDateField(),
        SizedBox(height: 16),
        _buildNotesField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'income_source_id':
              _incomeSourceId ?? (_incomeSources.first['id'] as String),
          'amount': double.parse(_amountController.text),
          'date': _dateController.text,
          'notes': _notesController.text,
        });
      },
      submitText: 'Add Income',
    );

    if (result != null) {
      try {
        final response = await _api.createIncome(result);
        if (response.statusCode == 201) {
          _fetchIncomes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Income added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add income')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteIncome(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Income'),
        content: Text('Are you sure you want to delete this income?'),
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
        final response = await _api.deleteIncome(id);
        if (response.statusCode == 200) {
          _fetchIncomes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Income deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete income')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewIncomeDetails(Map<String, dynamic> income) async {
    final amount = double.tryParse(income['amount']?.toString() ?? '0') ?? 0.0;
    final sourceBalance =
        double.tryParse(income['source']['balance']?.toString() ?? '0') ?? 0.0;

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
                color: Color(0xFF72140C).withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF72140C),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF72140C).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.trending_up,
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
                          'Income Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF72140C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete information about this income',
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
                        color: Color(0xFF72140C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF72140C).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Color(0xFF72140C),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72140C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Details
                    _buildDetailSection('Basic Information', [
                      _buildDetailRow(
                          'Notes', income['notes'] ?? 'N/A', Icons.notes),
                      _buildDetailRow('Category', income['category'] ?? 'N/A',
                          Icons.category),
                      _buildDetailRow('Date', income['date'] ?? 'N/A',
                          Icons.calendar_today),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Source Information', [
                      _buildDetailRow(
                          'Source Name',
                          income['source']['name'] ?? 'N/A',
                          Icons.account_balance),
                      _buildDetailRow('Source Type',
                          income['source']['type'] ?? 'N/A', Icons.business),
                      _buildDetailRow(
                          'Source Balance',
                          '\$${sourceBalance.toStringAsFixed(2)}',
                          Icons.account_balance_wallet),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created', income['created_at'] ?? 'N/A',
                          Icons.access_time),
                      _buildDetailRow('Updated', income['updated_at'] ?? 'N/A',
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
                    backgroundColor: Color(0xFF72140C),
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
                color: Color(0xFF72140C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF72140C),
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
              color: Color(0xFF72140C),
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Future<void> _editIncome(int id) async {
    try {
      final response = await _api.getIncome(id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final income = data['data'];
          // Pre-fill controllers
          _amountController.text = income['amount']?.toString() ?? '';
          _dateController.text = income['date'] ?? '';
          _notesController.text = income['notes'] ?? '';
          _incomeSourceId = income['income_source_id'];

          final result = await BottomSheetForm.show<Map<String, dynamic>>(
            context: context,
            title: 'Edit Income',
            header: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF72140C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.edit,
                size: 40,
                color: Color(0xFF72140C),
              ),
            ),
            formKey: _formKey,
            formFields: [
              _buildIncomeSourceDropdown(),
              SizedBox(height: 16),
              _buildAmountField(),
              SizedBox(height: 16),
              _buildDateField(),
              SizedBox(height: 16),
              _buildNotesField(),
            ],
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: () {
              Navigator.of(context).pop({
                'income_source_id':
                    _incomeSourceId ?? (_incomeSources.first['id'] as String),
                'amount': double.parse(_amountController.text),
                'date': _dateController.text,
                'notes': _notesController.text,
              });
            },
            submitText: 'Update Income',
          );

          if (result != null) {
            final updateResponse = await _api.updateIncome(id, result);
            if (updateResponse.statusCode == 200) {
              _fetchIncomes();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Income updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update income')),
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

  Widget _buildIncomeSourceDropdown() {
    return FormField<String>(
      builder: (FormFieldState<String> state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Income Source',
            prefixIcon: Icon(Icons.work),
            errorText: state.hasError ? state.errorText : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _incomeSourceId,
              isExpanded: true,
              items: _incomeSources.map((source) {
                return DropdownMenuItem<String>(
                  value: source['id'] as String,
                  child: Text(source['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _incomeSourceId = value;
                });
                state.didChange(value);
              },
            ),
          ),
        );
      },
      validator: (value) {
        if (value == null) {
          return 'Please select an income source';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixIcon: Icon(Icons.attach_money),
        prefixText: '\$',
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

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notes',
        prefixIcon: Icon(Icons.notes),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredIncomes = _incomes.where((income) {
      final query = _searchQuery.toLowerCase();
      final notes = (income['notes'] ?? '').toLowerCase();
      final sourceName = (income['source']['name'] ?? '').toLowerCase();
      return notes.contains(query) || sourceName.contains(query);
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
                    'Loading incomes...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : filteredIncomes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No incomes found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first income to start tracking',
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
                          labelText: 'Search incomes',
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
                        onRefresh: _fetchIncomes,
                        color: Color(0xFF72140C),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredIncomes.length,
                          itemBuilder: (context, index) {
                            final income = filteredIncomes[index];
                            final amount = double.tryParse(
                                    income['amount']?.toString() ?? '0') ??
                                0.0;
                            final sourceName =
                                income['source']['name'] ?? 'Unknown';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 0),
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
                                      color: Color(0xFF72140C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.trending_up,
                                      color: Color(0xFF72140C),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(income['notes'] ?? 'No notes'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${income['date'] ?? 'N/A'} • $sourceName'),
                                      Text(
                                          '${income['category'] ?? ''} • \$${amount.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        _viewIncomeDetails(income);
                                      } else if (value == 'edit') {
                                        _editIncome(income['id']);
                                      } else if (value == 'delete') {
                                        _deleteIncome(income['id']);
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
        onPressed: _addIncome,
        backgroundColor: Color(0xFF72140C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Income',
      ),
    );
  }
}
