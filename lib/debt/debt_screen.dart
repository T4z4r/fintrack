import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/custom_loader.dart';
import '../widgets/bottom_sheet_form.dart';

class DebtScreen extends StatefulWidget {
  @override
  _DebtScreenState createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> with TickerProviderStateMixin {
  late Api _api;
  List<Map<String, dynamic>> _debts = [];
  List<Map<String, dynamic>> _debtPayments = [];
  Map<int, List<Map<String, dynamic>>> _debtPaymentsByDebt = {};
  bool _isLoading = true;
  late TabController _tabController;

  // Debt form controllers
  final _debtFormKey = GlobalKey<FormState>();
  final _debtNameController = TextEditingController();
  final _debtAmountController = TextEditingController();
  final _debtDueDateController = TextEditingController();
  String _debtStatus = 'unpaid';

  // Debt payment form controllers
  final _debtPaymentFormKey = GlobalKey<FormState>();
  final _debtPaymentAmountController = TextEditingController();
  final _debtPaymentDateController = TextEditingController();
  final _debtPaymentMethodController = TextEditingController();
  final _debtPaymentNotesController = TextEditingController();
  int? _debtPaymentDebtId;

  @override
  void initState() {
    super.initState();
    // Get the API instance from AuthProvider
    _api = Provider.of<AuthProvider>(context, listen: false).api;
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debtNameController.dispose();
    _debtAmountController.dispose();
    _debtDueDateController.dispose();
    _debtPaymentAmountController.dispose();
    _debtPaymentDateController.dispose();
    _debtPaymentMethodController.dispose();
    _debtPaymentNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch debts
      final debtsResponse = await _api.getDebts();
      if (debtsResponse.statusCode == 200) {
        final debtsData = json.decode(debtsResponse.body);
        if (debtsData['success'] == true) {
          setState(() {
            _debts = List<Map<String, dynamic>>.from(debtsData['data']);
          });

          // Fetch debt payments for each debt
          for (var debt in _debts) {
            final paymentsResponse =
                await _api.getDebtPaymentsForDebt(debt['id']);
            if (paymentsResponse.statusCode == 200) {
              final paymentsData = json.decode(paymentsResponse.body);
              if (paymentsData['success'] == true) {
                setState(() {
                  _debtPaymentsByDebt[debt['id']] =
                      List<Map<String, dynamic>>.from(paymentsData['data']);
                });
              }
            }
          }
        }
      }

      // Fetch all debt payments
      final allPaymentsResponse = await _api.getDebtPayments();
      if (allPaymentsResponse.statusCode == 200) {
        final allPaymentsData = json.decode(allPaymentsResponse.body);
        if (allPaymentsData['success'] == true) {
          setState(() {
            _debtPayments =
                List<Map<String, dynamic>>.from(allPaymentsData['data']);
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addDebt() async {
    // Clear form
    _debtNameController.clear();
    _debtAmountController.clear();
    _debtDueDateController.clear();
    _debtStatus = 'unpaid';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Debt',
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
      formKey: _debtFormKey,
      formFields: [
        _buildDebtNameField(),
        SizedBox(height: 16),
        _buildDebtAmountField(),
        SizedBox(height: 16),
        _buildDebtDueDateField(),
        SizedBox(height: 16),
        _buildDebtStatusField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'name': _debtNameController.text,
          'amount': double.parse(_debtAmountController.text),
          'due_date': _debtDueDateController.text,
          'status': _debtStatus,
        });
      },
      submitText: 'Add Debt',
    );

    if (result != null) {
      try {
        final response = await _api.createDebt(result);
        if (response.statusCode == 201) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create debt')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addDebtPayment() async {
    if (_debts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please create a debt first')),
      );
      return;
    }

    // Clear form
    _debtPaymentAmountController.clear();
    _debtPaymentDateController.clear();
    _debtPaymentMethodController.clear();
    _debtPaymentNotesController.clear();
    _debtPaymentDebtId = null;

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Debt Payment',
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
      formKey: _debtPaymentFormKey,
      formFields: [
        _buildDebtPaymentDebtField(),
        SizedBox(height: 16),
        _buildDebtPaymentAmountField(),
        SizedBox(height: 16),
        _buildDebtPaymentDateField(),
        SizedBox(height: 16),
        _buildDebtPaymentMethodField(),
        SizedBox(height: 16),
        _buildDebtPaymentNotesField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'debt_id': _debtPaymentDebtId,
          'amount': double.parse(_debtPaymentAmountController.text),
          'payment_date': _debtPaymentDateController.text,
          'payment_method': _debtPaymentMethodController.text,
          'notes': _debtPaymentNotesController.text,
        });
      },
      submitText: 'Add Payment',
    );

    if (result != null) {
      try {
        final response = await _api.createDebtPayment(result);
        if (response.statusCode == 201) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt payment created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create debt payment')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteDebt(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Debt'),
        content: Text(
            'Are you sure you want to delete this debt? This will also delete all associated payments.'),
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
        final response = await _api.deleteDebt(id);
        if (response.statusCode == 200) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete debt')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteDebtPayment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Debt Payment'),
        content: Text('Are you sure you want to delete this debt payment?'),
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
        final response = await _api.deleteDebtPayment(id);
        if (response.statusCode == 200) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt payment deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete debt payment')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewDebtDetails(Map<String, dynamic> debt) async {
    final amount = double.tryParse(debt['amount']?.toString() ?? '0') ?? 0.0;
    final payments = _debtPaymentsByDebt[debt['id']] ?? [];
    final totalPaid = payments.fold<double>(
        0.0,
        (double sum, payment) =>
            sum +
            (double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0));
    final remainingAmount = amount - totalPaid;

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
                      Icons.credit_card,
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
                          debt['name'] ?? 'Unnamed Debt',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete debt information and payment history',
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
                    // Amount overview
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '\$${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Paid',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '\$${totalPaid.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Remaining',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '\$${remainingAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: remainingAmount > 0
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Details
                    _buildDetailSection('Debt Information', [
                      _buildDetailRow(
                          'Name', debt['name'] ?? 'N/A', Icons.business),
                      _buildDetailRow(
                          'Status', debt['status'] ?? 'N/A', Icons.info),
                      _buildDetailRow('Amount',
                          '\$${amount.toStringAsFixed(2)}', Icons.attach_money),
                      _buildDetailRow('Due Date', debt['due_date'] ?? 'N/A',
                          Icons.calendar_today),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created', debt['created_at'] ?? 'N/A',
                          Icons.access_time),
                      _buildDetailRow(
                          'Updated', debt['updated_at'] ?? 'N/A', Icons.update),
                    ]),
                    if (payments.isNotEmpty) ...[
                      SizedBox(height: 16),
                      _buildDetailSection('Recent Payments', [
                        ...payments.take(3).map((payment) => _buildDetailRow(
                              '${payment['payment_date'] ?? 'N/A'} - ${payment['payment_method'] ?? 'N/A'}',
                              '\$${(double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                              Icons.payment,
                            )),
                        if (payments.length > 3)
                          _buildDetailRow(
                              'And ${payments.length - 3} more payments',
                              '',
                              Icons.more_horiz),
                      ]),
                    ],
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

  Future<void> _editDebt(int id) async {
    try {
      final response = await _api.getDebt(id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final debt = data['data'];
          // Pre-fill controllers
          _debtNameController.text = debt['name'] ?? '';
          _debtAmountController.text = debt['amount']?.toString() ?? '';
          _debtDueDateController.text = debt['due_date'] ?? '';
          _debtStatus = debt['status'] ?? 'unpaid';

          final result = await BottomSheetForm.show<Map<String, dynamic>>(
            context: context,
            title: 'Edit Debt',
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
            formKey: _debtFormKey,
            formFields: [
              _buildDebtNameField(),
              SizedBox(height: 16),
              _buildDebtAmountField(),
              SizedBox(height: 16),
              _buildDebtDueDateField(),
              SizedBox(height: 16),
              _buildDebtStatusField(),
            ],
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: () {
              Navigator.of(context).pop({
                'name': _debtNameController.text,
                'amount': double.parse(_debtAmountController.text),
                'due_date': _debtDueDateController.text,
                'status': _debtStatus,
              });
            },
            submitText: 'Update Debt',
          );

          if (result != null) {
            final updateResponse = await _api.updateDebt(id, result);
            if (updateResponse.statusCode == 200) {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Debt updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update debt')),
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

  Widget _buildDebtNameField() {
    return TextFormField(
      controller: _debtNameController,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) => value?.isEmpty ?? true ? 'Please enter name' : null,
    );
  }

  Widget _buildDebtAmountField() {
    return TextFormField(
      controller: _debtAmountController,
      decoration: InputDecoration(labelText: 'Amount'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter amount' : null,
    );
  }

  Widget _buildDebtDueDateField() {
    return TextFormField(
      controller: _debtDueDateController,
      decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter due date' : null,
    );
  }

  Widget _buildDebtStatusField() {
    return DropdownButtonFormField<String>(
      value: _debtStatus,
      decoration: InputDecoration(labelText: 'Status'),
      items: ['unpaid', 'partial']
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      onChanged: (value) => setState(() => _debtStatus = value!),
    );
  }

  Widget _buildDebtPaymentDebtField() {
    return DropdownButtonFormField<int>(
      value: _debtPaymentDebtId,
      decoration: InputDecoration(labelText: 'Select Debt'),
      items: _debts.map((debt) {
        return DropdownMenuItem<int>(
          value: debt['id'],
          child: Text(debt['name'] ?? 'Unnamed Debt'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _debtPaymentDebtId = value;
        });
      },
      validator: (value) => value == null ? 'Please select a debt' : null,
    );
  }

  Widget _buildDebtPaymentAmountField() {
    return TextFormField(
      controller: _debtPaymentAmountController,
      decoration: InputDecoration(labelText: 'Amount'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter amount' : null,
    );
  }

  Widget _buildDebtPaymentDateField() {
    return TextFormField(
      controller: _debtPaymentDateController,
      decoration: InputDecoration(labelText: 'Payment Date (YYYY-MM-DD)'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter payment date' : null,
    );
  }

  Widget _buildDebtPaymentMethodField() {
    return TextFormField(
      controller: _debtPaymentMethodController,
      decoration: InputDecoration(labelText: 'Payment Method'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter payment method' : null,
    );
  }

  Widget _buildDebtPaymentNotesField() {
    return TextFormField(
      controller: _debtPaymentNotesController,
      decoration: InputDecoration(labelText: 'Notes'),
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
                  CustomLoader(
                    color: Color(0xFF72140C),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading debts...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF72140C),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF72140C),
                  tabs: [
                    Tab(text: 'Debts'),
                    Tab(text: 'Payments'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtsTab(),
                      _buildPaymentsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addDebt,
              backgroundColor: Color(0xFF72140C),
              child: Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Debt',
            )
          : FloatingActionButton(
              onPressed: _addDebtPayment,
              backgroundColor: Color(0xFF72140C),
              child: Icon(Icons.payment, color: Colors.white),
              tooltip: 'Add Payment',
            ),
    );
  }

  Widget _buildDebtsTab() {
    return _debts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No debts found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first debt to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _fetchData,
            color: Color(0xFF72140C),
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _debts.length,
              itemBuilder: (context, index) {
                final debt = _debts[index];
                final payments = _debtPaymentsByDebt[debt['id']] ?? [];
                final totalPaid = payments.fold<double>(
                    0.0,
                    (double sum, payment) =>
                        sum +
                        (double.tryParse(
                                payment['amount']?.toString() ?? '0') ??
                            0.0));
                final debtAmount =
                    double.tryParse(debt['amount']?.toString() ?? '0') ?? 0.0;
                final remainingAmount = debtAmount - totalPaid;
                final isPaidOff = remainingAmount <= 0;
                final isUnpaid = debt['status'] == 'unpaid';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
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
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPaidOff
                                  ? Colors.green.withOpacity(0.1)
                                  : isUnpaid
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPaidOff
                                  ? Icons.check_circle
                                  : Icons.credit_card,
                              color: isPaidOff
                                  ? Colors.green
                                  : isUnpaid
                                      ? Colors.red
                                      : Colors.orange,
                              size: 20,
                            ),
                          ),
                          title: Text(debt['name'] ?? 'Unnamed Debt'),
                          subtitle: Text(
                            'Status: ${debt['status'] ?? 'N/A'} • Due: ${debt['due_date'] ?? 'N/A'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'view') {
                                _viewDebtDetails(debt);
                              } else if (value == 'edit') {
                                _editDebt(debt['id']);
                              } else if (value == 'delete') {
                                _deleteDebt(debt['id']);
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
                                  leading:
                                      Icon(Icons.edit, color: Colors.orange),
                                  title: Text('Edit'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading:
                                      Icon(Icons.delete, color: Colors.red),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Amount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '\$${debtAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Remaining',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '\$${remainingAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isPaidOff
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (payments.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Payments (${payments.length})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF72140C),
                                      ),
                                    ),
                                    Text(
                                      'Total Paid: \$${totalPaid.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ...payments.take(2).map((payment) => Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${payment['payment_date'] ?? 'N/A'} • ${payment['payment_method'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            '\$${(double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                if (payments.length > 2)
                                  Text(
                                    '...and ${payments.length - 2} more payments',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                              if (isPaidOff) ...[
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PAID OFF',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildPaymentsTab() {
    return _debtPayments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No debt payments found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add payments to track your debt progress',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _fetchData,
            color: Color(0xFF72140C),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _debtPayments.length,
              itemBuilder: (context, index) {
                final payment = _debtPayments[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title:
                          Text(payment['payment_method'] ?? 'Unknown Method'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${payment['payment_date'] ?? 'N/A'} • Debt ID: ${payment['debt_id'] ?? 'N/A'}'),
                          if (payment['notes'] != null) Text(payment['notes']),
                          Text(
                              '\$${(double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteDebtPayment(payment['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
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
          );
  }
}
