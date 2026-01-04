import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/custom_loader.dart';
import '../widgets/bottom_sheet_form.dart';

class InvestmentScreen extends StatefulWidget {
  @override
  _InvestmentScreenState createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  late Api _api;
  List<Map<String, dynamic>> _investments = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Form controllers for bottom sheet
  final _investmentFormKey = GlobalKey<FormState>();
  final _investmentNameController = TextEditingController();
  final _investmentAmountInvestedController = TextEditingController();
  final _investmentCurrentValueController = TextEditingController();
  final _investmentDateInvestedController = TextEditingController();
  final _investmentDescriptionController = TextEditingController();
  String _investmentType = 'stocks';

  @override
  void initState() {
    super.initState();
    // Get the API instance from AuthProvider
    _api = Provider.of<AuthProvider>(context, listen: false).api;
    _fetchInvestments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _investmentNameController.dispose();
    _investmentAmountInvestedController.dispose();
    _investmentCurrentValueController.dispose();
    _investmentDateInvestedController.dispose();
    _investmentDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvestments() async {
    try {
      final response = await _api.getInvestments();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _investments = List<Map<String, dynamic>>.from(data['data']);
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

  Future<void> _addInvestment() async {
    // Clear form
    _investmentNameController.clear();
    _investmentAmountInvestedController.clear();
    _investmentCurrentValueController.clear();
    _investmentDateInvestedController.clear();
    _investmentDescriptionController.clear();
    _investmentType = 'stocks';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Investment',
      formKey: _investmentFormKey,
      formFields: [
        _buildInvestmentNameField(),
        SizedBox(height: 16),
        _buildInvestmentTypeField(),
        SizedBox(height: 16),
        _buildInvestmentAmountInvestedField(),
        SizedBox(height: 16),
        _buildInvestmentCurrentValueField(),
        SizedBox(height: 16),
        _buildInvestmentDateInvestedField(),
        SizedBox(height: 16),
        _buildInvestmentDescriptionField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'name': _investmentNameController.text,
          'type': _investmentType,
          'amount_invested':
              double.parse(_investmentAmountInvestedController.text),
          'current_value': double.parse(_investmentCurrentValueController.text),
          'date_invested': _investmentDateInvestedController.text,
          'description': _investmentDescriptionController.text,
        });
      },
      submitText: 'Add Investment',
    );

    if (result != null) {
      try {
        final response = await _api.createInvestment(result);
        if (response.statusCode == 201) {
          _fetchInvestments();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Investment created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create investment')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvestment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Investment'),
        content: Text('Are you sure you want to delete this investment?'),
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
        final response = await _api.deleteInvestment(id);
        if (response.statusCode == 200) {
          _fetchInvestments();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Investment deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete investment')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInvestmentNameField() {
    return TextFormField(
      controller: _investmentNameController,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter a name' : null,
    );
  }

  Widget _buildInvestmentTypeField() {
    return DropdownButtonFormField<String>(
      value: _investmentType,
      decoration: InputDecoration(labelText: 'Type'),
      items: ['stocks', 'bonds', 'real_estate', 'crypto', 'other']
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      onChanged: (value) => setState(() => _investmentType = value!),
    );
  }

  Widget _buildInvestmentAmountInvestedField() {
    return TextFormField(
      controller: _investmentAmountInvestedController,
      decoration: InputDecoration(labelText: 'Amount Invested'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter amount' : null,
    );
  }

  Widget _buildInvestmentCurrentValueField() {
    return TextFormField(
      controller: _investmentCurrentValueController,
      decoration: InputDecoration(labelText: 'Current Value'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter current value' : null,
    );
  }

  Widget _buildInvestmentDateInvestedField() {
    return TextFormField(
      controller: _investmentDateInvestedController,
      decoration: InputDecoration(labelText: 'Date Invested (YYYY-MM-DD)'),
      validator: (value) => value?.isEmpty ?? true ? 'Please enter date' : null,
    );
  }

  Widget _buildInvestmentDescriptionField() {
    return TextFormField(
      controller: _investmentDescriptionController,
      decoration: InputDecoration(labelText: 'Description'),
      maxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvestments = _investments.where((investment) {
      final query = _searchQuery.toLowerCase();
      final name = (investment['name'] ?? '').toLowerCase();
      final type = (investment['type'] ?? '').toLowerCase();
      return name.contains(query) || type.contains(query);
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
                    'Loading investments...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : filteredInvestments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No investments found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first investment to track your portfolio',
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
                          labelText: 'Search investments',
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
                        onRefresh: _fetchInvestments,
                        color: Color(0xFF72140C),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredInvestments.length,
                          itemBuilder: (context, index) {
                            final investment = filteredInvestments[index];
                            final invested = double.tryParse(
                                    investment['amount_invested']?.toString() ??
                                        '0') ??
                                0.0;
                            final current = double.tryParse(
                                    investment['current_value']?.toString() ??
                                        '0') ??
                                0.0;
                            final profitLoss = current - invested;
                            final isProfit = profitLoss >= 0;

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
                                      color:
                                          (isProfit ? Colors.green : Colors.red)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.show_chart,
                                      color:
                                          isProfit ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(investment['name'] ??
                                      'Unnamed Investment'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(investment['type'] ?? 'N/A'),
                                      Text(
                                          'Invested: \$${invested.toStringAsFixed(2)} • Current: \$${current.toStringAsFixed(2)}'),
                                      Text(
                                          '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteInvestment(investment['id']);
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
        onPressed: _addInvestment,
        backgroundColor: Color(0xFF72140C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Investment',
      ),
    );
  }
}

