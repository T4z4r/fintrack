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
  final _investmentExpectedReturnController = TextEditingController();
  final _investmentStartDateController = TextEditingController();
  String _investmentStatus = 'active';

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
    _investmentExpectedReturnController.dispose();
    _investmentStartDateController.dispose();
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
    _investmentExpectedReturnController.clear();
    _investmentStartDateController.clear();
    _investmentStatus = 'active';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Investment',
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
      formKey: _investmentFormKey,
      formFields: [
        _buildInvestmentNameField(),
        SizedBox(height: 16),
        _buildInvestmentStatusField(),
        SizedBox(height: 16),
        _buildInvestmentAmountInvestedField(),
        SizedBox(height: 16),
        _buildInvestmentExpectedReturnField(),
        SizedBox(height: 16),
        _buildInvestmentStartDateField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'name': _investmentNameController.text,
          'status': _investmentStatus,
          'amount_invested':
              double.parse(_investmentAmountInvestedController.text),
          'expected_return':
              double.parse(_investmentExpectedReturnController.text),
          'start_date': _investmentStartDateController.text,
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

  Future<void> _viewInvestmentDetails(Map<String, dynamic> investment) async {
    final amountInvested =
        double.tryParse(investment['amount_invested']?.toString() ?? '0') ??
            0.0;
    final expectedReturn =
        double.tryParse(investment['expected_return']?.toString() ?? '0') ??
            0.0;

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
                      Icons.show_chart,
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
                          investment['name'] ?? 'Unnamed Investment',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF72140C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete investment information and details',
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
                            '\$${amountInvested.toStringAsFixed(2)}',
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
                    _buildDetailSection('Investment Information', [
                      _buildDetailRow(
                          'Name', investment['name'] ?? 'N/A', Icons.business),
                      _buildDetailRow(
                          'Status', investment['status'] ?? 'N/A', Icons.info),
                      _buildDetailRow(
                          'Amount Invested',
                          '\$${amountInvested.toStringAsFixed(2)}',
                          Icons.attach_money),
                      _buildDetailRow(
                          'Expected Return',
                          '${expectedReturn.toStringAsFixed(2)}%',
                          Icons.trending_up),
                      _buildDetailRow(
                          'Start Date',
                          investment['start_date'] ?? 'N/A',
                          Icons.calendar_today),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created',
                          investment['created_at'] ?? 'N/A', Icons.access_time),
                      _buildDetailRow('Updated',
                          investment['updated_at'] ?? 'N/A', Icons.update),
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

  Future<void> _editInvestment(int id) async {
    try {
      final response = await _api.getInvestment(id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final investment = data['data'];
          // Pre-fill controllers
          _investmentNameController.text = investment['name'] ?? '';
          _investmentAmountInvestedController.text =
              investment['amount_invested']?.toString() ?? '';
          _investmentExpectedReturnController.text =
              investment['expected_return']?.toString() ?? '';
          _investmentStartDateController.text = investment['start_date'] ?? '';
          _investmentStatus = investment['status'] ?? 'active';

          final result = await BottomSheetForm.show<Map<String, dynamic>>(
            context: context,
            title: 'Edit Investment',
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
            formKey: _investmentFormKey,
            formFields: [
              _buildInvestmentNameField(),
              SizedBox(height: 16),
              _buildInvestmentStatusField(),
              SizedBox(height: 16),
              _buildInvestmentAmountInvestedField(),
              SizedBox(height: 16),
              _buildInvestmentExpectedReturnField(),
              SizedBox(height: 16),
              _buildInvestmentStartDateField(),
            ],
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: () {
              Navigator.of(context).pop({
                'name': _investmentNameController.text,
                'status': _investmentStatus,
                'amount_invested':
                    double.parse(_investmentAmountInvestedController.text),
                'expected_return':
                    double.parse(_investmentExpectedReturnController.text),
                'start_date': _investmentStartDateController.text,
              });
            },
            submitText: 'Update Investment',
          );

          if (result != null) {
            final updateResponse = await _api.updateInvestment(id, result);
            if (updateResponse.statusCode == 200) {
              _fetchInvestments();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Investment updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update investment')),
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

  Widget _buildInvestmentNameField() {
    return TextFormField(
      controller: _investmentNameController,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter a name' : null,
    );
  }

  Widget _buildInvestmentStatusField() {
    return DropdownButtonFormField<String>(
      value: _investmentStatus,
      decoration: InputDecoration(labelText: 'Status'),
      items: ['active', 'inactive']
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      onChanged: (value) => setState(() => _investmentStatus = value!),
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

  Widget _buildInvestmentExpectedReturnField() {
    return TextFormField(
      controller: _investmentExpectedReturnController,
      decoration: InputDecoration(labelText: 'Expected Return (%)'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter expected return' : null,
    );
  }

  Widget _buildInvestmentStartDateField() {
    return TextFormField(
      controller: _investmentStartDateController,
      decoration: InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
      validator: (value) => value?.isEmpty ?? true ? 'Please enter date' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvestments = _investments.where((investment) {
      final query = _searchQuery.toLowerCase();
      final name = (investment['name'] ?? '').toLowerCase();
      final status = (investment['status'] ?? '').toLowerCase();
      return name.contains(query) || status.contains(query);
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
                            final expectedReturn = double.tryParse(
                                    investment['expected_return']?.toString() ??
                                        '0') ??
                                0.0;

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
                                      Icons.show_chart,
                                      color: Color(0xFF72140C),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(investment['name'] ??
                                      'Unnamed Investment'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${investment['status'] ?? 'N/A'} • ${investment['start_date'] ?? 'N/A'}'),
                                      Text(
                                          'Invested: \$${invested.toStringAsFixed(2)} • Expected Return: ${expectedReturn.toStringAsFixed(2)}%'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        _viewInvestmentDetails(investment);
                                      } else if (value == 'edit') {
                                        _editInvestment(investment['id']);
                                      } else if (value == 'delete') {
                                        _deleteInvestment(investment['id']);
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
        onPressed: _addInvestment,
        backgroundColor: Color(0xFF72140C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Investment',
      ),
    );
  }
}
