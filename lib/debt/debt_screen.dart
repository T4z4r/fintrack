import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';

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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DebtFormDialog(),
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DebtPaymentFormDialog(debts: _debts),
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
              padding: EdgeInsets.all(16),
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
                final isOverdue = debt['status'] == 'overdue';

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
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPaidOff
                                  ? Colors.green.withOpacity(0.1)
                                  : isOverdue
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
                                  : isOverdue
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
                              if (value == 'delete') {
                                _deleteDebt(debt['id']);
                              }
                            },
                            itemBuilder: (context) => [
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
                          padding: const EdgeInsets.all(16),
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

class DebtFormDialog extends StatefulWidget {
  @override
  _DebtFormDialogState createState() => _DebtFormDialogState();
}

class _DebtFormDialogState extends State<DebtFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  String _status = 'partial';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Debt'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter name' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter amount' : null,
              ),
              TextFormField(
                controller: _dueDateController,
                decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter due date' : null,
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: 'Status'),
                items: ['partial', 'paid', 'overdue']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'amount': double.parse(_amountController.text),
                'due_date': _dueDateController.text,
                'status': _status,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class DebtPaymentFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> debts;

  const DebtPaymentFormDialog({Key? key, required this.debts})
      : super(key: key);

  @override
  _DebtPaymentFormDialogState createState() => _DebtPaymentFormDialogState();
}

class _DebtPaymentFormDialogState extends State<DebtPaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();
  int? _debtId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Debt Payment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _debtId,
                decoration: InputDecoration(labelText: 'Select Debt'),
                items: widget.debts.map((debt) {
                  return DropdownMenuItem<int>(
                    value: debt['id'],
                    child: Text(debt['name'] ?? 'Unnamed Debt'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _debtId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a debt' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter amount' : null,
              ),
              TextFormField(
                controller: _paymentDateController,
                decoration:
                    InputDecoration(labelText: 'Payment Date (YYYY-MM-DD)'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter payment date' : null,
              ),
              TextFormField(
                controller: _paymentMethodController,
                decoration: InputDecoration(labelText: 'Payment Method'),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter payment method'
                    : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop({
                'debt_id': _debtId,
                'amount': double.parse(_amountController.text),
                'payment_date': _paymentDateController.text,
                'payment_method': _paymentMethodController.text,
                'notes': _notesController.text,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
