import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/bottom_sheet_form.dart';

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
  final _descriptionController = TextEditingController();
  int? _incomeSourceId;

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
    _descriptionController.dispose();
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
              _incomeSourceId = _incomeSources.first['id'];
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
    _descriptionController.clear();

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Income',
      formFields: [
        _buildIncomeSourceDropdown(),
        SizedBox(height: 16),
        _buildAmountField(),
        SizedBox(height: 16),
        _buildDateField(),
        SizedBox(height: 16),
        _buildDescriptionField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submitIncome,
      submitText: 'Add Income',
    );
  }

  void _submitIncome() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop({
        'income_source_id': _incomeSourceId ?? _incomeSources.first['id'],
        'amount': double.parse(_amountController.text),
        'date': _dateController.text,
        'description': _descriptionController.text,
      });
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

  Widget _buildIncomeSourceDropdown() {
    return FormField<int>(
      builder: (FormFieldState<int> state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Income Source',
            prefixIcon: Icon(Icons.work),
            errorText: state.hasError ? state.errorText : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _incomeSourceId,
              isExpanded: true,
              items: _incomeSources.map((source) {
                return DropdownMenuItem<int>(
                  value: source['id'],
                  child: Text(source['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
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
    return TextFormField(
      controller: _dateController,
      decoration: InputDecoration(
        labelText: 'Date',
        prefixIcon: Icon(Icons.calendar_today),
        hintText: 'YYYY-MM-DD',
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter date';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Loading incomes...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _incomes.isEmpty
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
              : RefreshIndicator(
                  onRefresh: _fetchIncomes,
                  color: Color(0xFF72140C),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _incomes.length,
                    itemBuilder: (context, index) {
                      final income = _incomes[index];
                      final amount = income['amount'] ?? 0;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.trending_up,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      income['description'] ?? 'No description',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      income['date'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteIncome(income['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
