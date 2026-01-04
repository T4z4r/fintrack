import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/bottom_sheet_form.dart';
import '../widgets/date_picker_field.dart';

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
  final _searchController = TextEditingController();
  String _searchQuery = '';
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
      formKey: _formKey,
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
      onSubmit: () {
        Navigator.of(context).pop({
          'income_source_id': _incomeSourceId ?? _incomeSources.first['id'],
          'amount': double.parse(_amountController.text),
          'date': _dateController.text,
          'description': _descriptionController.text,
        });
      },
      submitText: 'Add Income',
    );
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
    final filteredIncomes = _incomes.where((income) {
      final query = _searchQuery.toLowerCase();
      final description = (income['description'] ?? '').toLowerCase();
      final incomeSource = _incomeSources.firstWhere(
        (source) => source['id'] == income['income_source_id'],
        orElse: () => {'name': ''},
      );
      final sourceName = (incomeSource['name'] ?? '').toLowerCase();
      return description.contains(query) || sourceName.contains(query);
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
                      padding: EdgeInsets.all(16),
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
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredIncomes.length,
                          itemBuilder: (context, index) {
                            final income = filteredIncomes[index];
                            final amount = double.tryParse(
                                    income['amount']?.toString() ?? '0') ??
                                0.0;
                            final incomeSource = _incomeSources.firstWhere(
                              (source) =>
                                  source['id'] == income['income_source_id'],
                              orElse: () => {'name': 'Unknown'},
                            );
                            final sourceName =
                                incomeSource['name'] ?? 'Unknown';

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
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.trending_up,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(income['description'] ??
                                      'No description'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${income['date'] ?? 'N/A'} • $sourceName'),
                                      Text('\$${amount.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteIncome(income['id']);
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
        onPressed: _addIncome,
        backgroundColor: Color(0xFF72140C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Income',
      ),
    );
  }
}
