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
  String _debtStatus = 'partial';

  // Debt payment form controllers
  final _debtPaymentFormKey = GlobalKey<FormState>();
  final _debtPaymentAmountController = TextEditingController();
  final _debtPaymentDateController = TextEditingController();
  final _debtPaymentMethodController = TextEditingController();
  final _debtPaymentNotesController = TextEditingController();
  int? _debtPaymentDebtId;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

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
    _searchController.dispose();
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
    _debtStatus = 'partial';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Debt',
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
      items: ['unpaid', 'partial', 'paid', 'overdue']
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                            ),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _tabController.index == 0
                            ? _addDebt
                            : _addDebtPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        icon: Icon(Icons.add,
                            color: Theme.of(context).colorScheme.onPrimary),
                        label: Text(_tabController.index == 0
                            ? 'Add Debt'
                            : 'Add Payment'),
                      ),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildDebtsTab() {
    final filteredDebts = _debts.where((debt) {
      final query = _searchQuery.toLowerCase();
      final name = (debt['name'] ?? '').toLowerCase();
      final amount = (debt['amount']?.toString() ?? '').toLowerCase();
      final status = (debt['status'] ?? '').toLowerCase();
      return name.contains(query) ||
          amount.contains(query) ||
          status.contains(query);
    }).toList();

    return filteredDebts.isEmpty
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
              itemCount: filteredDebts.length,
              itemBuilder: (context, index) {
                final debt = filteredDebts[index];
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
                final Color statusColor = isPaidOff
                    ? Colors.green
                    : isOverdue
                        ? Colors.red
                        : Colors.orange;

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
                              color: statusColor.withOpacity(0.1),
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
                            'Status: ${debt['status'] ?? 'N/A'} • Due: ${_formatDate(debt['due_date'])}',
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
    final filteredPayments = _debtPayments.where((payment) {
      final query = _searchQuery.toLowerCase();
      final method = (payment['payment_method'] ?? '').toLowerCase();
      final amount = (payment['amount']?.toString() ?? '').toLowerCase();
      final notes = (payment['notes'] ?? '').toLowerCase();
      return method.contains(query) ||
          amount.contains(query) ||
          notes.contains(query);
    }).toList();

    return filteredPayments.isEmpty
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
              itemCount: filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = filteredPayments[index];
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
