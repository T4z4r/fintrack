import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/custom_loader.dart';
import '../widgets/bottom_sheet_form.dart';

class BudgetScreen extends StatefulWidget {
  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  late Api _api;
  List<Map<String, dynamic>> _budgets = [];
  Map<int, List<Map<String, dynamic>>> _budgetItems = {};
  bool _isLoading = true;
  late TabController _tabController;

  // Form controllers for bottom sheet
  final _budgetFormKey = GlobalKey<FormState>();
  final _budgetNameController = TextEditingController();
  final _budgetDescriptionController = TextEditingController();
  String _budgetTimePeriod = 'monthly';
  String _budgetCategoryType = 'expense';

  // Budget item form controllers
  final _budgetItemFormKey = GlobalKey<FormState>();
  final _budgetItemNameController = TextEditingController();
  final _budgetItemPlannedAmountController = TextEditingController();
  final _budgetItemCategoryController = TextEditingController();
  final _budgetItemDescriptionController = TextEditingController();
  String _budgetItemCategoryType = 'expense';

  // Update spent amount form
  final _updateSpentFormKey = GlobalKey<FormState>();
  final _spentAmountController = TextEditingController();

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
    _budgetNameController.dispose();
    _budgetDescriptionController.dispose();
    _budgetItemNameController.dispose();
    _budgetItemPlannedAmountController.dispose();
    _budgetItemCategoryController.dispose();
    _budgetItemDescriptionController.dispose();
    _spentAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final budgetsResponse = await _api.getBudgets();
      if (budgetsResponse.statusCode == 200) {
        final budgetsData = json.decode(budgetsResponse.body);
        if (budgetsData['success'] == true) {
          setState(() {
            _budgets = List<Map<String, dynamic>>.from(budgetsData['data']);
            // Extract budget items from embedded data
            for (var budget in _budgets) {
              _budgetItems[budget['id']] =
                  List<Map<String, dynamic>>.from(budget['budget_items'] ?? []);
            }
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

  Future<void> _addBudget() async {
    // Clear form
    _budgetNameController.clear();
    _budgetDescriptionController.clear();
    _budgetTimePeriod = 'monthly';
    _budgetCategoryType = 'expense';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Budget',
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
      formKey: _budgetFormKey,
      formFields: [
        _buildBudgetNameField(),
        SizedBox(height: 16),
        _buildBudgetDescriptionField(),
        SizedBox(height: 16),
        _buildBudgetTimePeriodField(),
        SizedBox(height: 16),
        _buildBudgetCategoryTypeField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'name': _budgetNameController.text,
          'description': _budgetDescriptionController.text,
          'time_period': _budgetTimePeriod,
          'category_type': _budgetCategoryType,
        });
      },
      submitText: 'Add Budget',
    );

    if (result != null) {
      try {
        final response = await _api.createBudget(result);
        if (response.statusCode == 201) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Budget created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create budget')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addBudgetItem(int budgetId) async {
    // Clear form
    _budgetItemNameController.clear();
    _budgetItemPlannedAmountController.clear();
    _budgetItemCategoryController.clear();
    _budgetItemDescriptionController.clear();
    _budgetItemCategoryType = 'expense';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Budget Item',
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
      formKey: _budgetItemFormKey,
      formFields: [
        _buildBudgetItemNameField(),
        SizedBox(height: 16),
        _buildBudgetItemPlannedAmountField(),
        SizedBox(height: 16),
        _buildBudgetItemCategoryField(),
        SizedBox(height: 16),
        _buildBudgetItemCategoryTypeField(),
        SizedBox(height: 16),
        _buildBudgetItemDescriptionField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'budget_id': budgetId,
          'name': _budgetItemNameController.text,
          'planned_amount':
              double.parse(_budgetItemPlannedAmountController.text),
          'category_type': _budgetItemCategoryType,
          'category': _budgetItemCategoryController.text,
          'description': _budgetItemDescriptionController.text,
        });
      },
      submitText: 'Add Budget Item',
    );

    if (result != null) {
      try {
        final response = await _api.createBudgetItem(result);
        if (response.statusCode == 201) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Budget item created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create budget item')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateBudgetItemSpentAmount(int itemId) async {
    // Clear form
    _spentAmountController.clear();

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Update Spent Amount',
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
      formKey: _updateSpentFormKey,
      formFields: [
        _buildSpentAmountField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'spent_amount': double.parse(_spentAmountController.text),
        });
      },
      submitText: 'Update',
    );

    if (result != null) {
      try {
        final response = await _api.updateBudgetItemSpentAmount(itemId, result);
        if (response.statusCode == 200) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Spent amount updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update spent amount')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteBudget(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Budget'),
        content: Text(
            'Are you sure you want to delete this budget? This will also delete all budget items.'),
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
        final response = await _api.deleteBudget(id);
        if (response.statusCode == 200) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Budget deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete budget')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteBudgetItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Budget Item'),
        content: Text('Are you sure you want to delete this budget item?'),
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
        final response = await _api.deleteBudgetItem(id);
        if (response.statusCode == 200) {
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Budget item deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete budget item')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewBudgetDetails(Map<String, dynamic> budget) async {
    final plannedAmount =
        double.tryParse(budget['planned_amount']?.toString() ?? '0') ?? 0.0;
    final spentAmount =
        double.tryParse(budget['spent_amount']?.toString() ?? '0') ?? 0.0;
    final usagePercentage = budget['usage_percentage'] ?? 0.0;
    final remainingAmount =
        double.tryParse(budget['remaining_amount']?.toString() ?? '0') ?? 0.0;

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
                      Icons.pie_chart,
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
                          budget['name'] ?? 'Unnamed Budget',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF72140C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete budget information and details',
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
                        color: Color(0xFF72140C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF72140C).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Planned Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '\$${plannedAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF72140C),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '\$${spentAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[600],
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
                                  color: remainingAmount >= 0
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Progress
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Usage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72140C),
                            ),
                          ),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: usagePercentage / 100.0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (budget['calculated_status'] == 'exceeded')
                                  ? Colors.red
                                  : Color(0xFF72140C),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${usagePercentage.toStringAsFixed(1)}% used',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Status: ${budget['calculated_status'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: (budget['calculated_status'] == 'exceeded')
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Details
                    _buildDetailSection('Budget Information', [
                      _buildDetailRow('Time Period',
                          budget['time_period'] ?? 'N/A', Icons.schedule),
                      _buildDetailRow('Category Type',
                          budget['category_type'] ?? 'N/A', Icons.category),
                      _buildDetailRow(
                          'Status', budget['status'] ?? 'N/A', Icons.info),
                      _buildDetailRow('Month', budget['month'] ?? 'N/A',
                          Icons.calendar_view_month),
                      _buildDetailRow('Year', budget['year'] ?? 'N/A',
                          Icons.calendar_today),
                      if (budget['description'] != null)
                        _buildDetailRow('Description', budget['description'],
                            Icons.description),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created', budget['created_at'] ?? 'N/A',
                          Icons.access_time),
                      _buildDetailRow('Updated', budget['updated_at'] ?? 'N/A',
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

  Future<void> _editBudget(int id) async {
    try {
      final response = await _api.getBudget(id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final budget = data['data'];
          // Pre-fill controllers
          _budgetNameController.text = budget['name'] ?? '';
          _budgetDescriptionController.text = budget['description'] ?? '';
          _budgetTimePeriod = budget['time_period'] ?? 'monthly';
          _budgetCategoryType = budget['category_type'] ?? 'expense';

          final result = await BottomSheetForm.show<Map<String, dynamic>>(
            context: context,
            title: 'Edit Budget',
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
            formKey: _budgetFormKey,
            formFields: [
              _buildBudgetNameField(),
              SizedBox(height: 16),
              _buildBudgetDescriptionField(),
              SizedBox(height: 16),
              _buildBudgetTimePeriodField(),
              SizedBox(height: 16),
              _buildBudgetCategoryTypeField(),
            ],
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: () {
              Navigator.of(context).pop({
                'name': _budgetNameController.text,
                'description': _budgetDescriptionController.text,
                'time_period': _budgetTimePeriod,
                'category_type': _budgetCategoryType,
              });
            },
            submitText: 'Update Budget',
          );

          if (result != null) {
            final updateResponse = await _api.updateBudget(id, result);
            if (updateResponse.statusCode == 200) {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Budget updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update budget')),
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

  Widget _buildBudgetNameField() {
    return TextFormField(
      controller: _budgetNameController,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter a name' : null,
    );
  }

  Widget _buildBudgetDescriptionField() {
    return TextFormField(
      controller: _budgetDescriptionController,
      decoration: InputDecoration(labelText: 'Description'),
      maxLines: 3,
    );
  }

  Widget _buildBudgetTimePeriodField() {
    return DropdownButtonFormField<String>(
      value: _budgetTimePeriod,
      decoration: InputDecoration(labelText: 'Time Period'),
      items: ['monthly', 'yearly', 'weekly']
          .map((period) => DropdownMenuItem(
                value: period,
                child: Text(period),
              ))
          .toList(),
      onChanged: (value) => setState(() => _budgetTimePeriod = value!),
    );
  }

  Widget _buildBudgetCategoryTypeField() {
    return DropdownButtonFormField<String>(
      value: _budgetCategoryType,
      decoration: InputDecoration(labelText: 'Category Type'),
      items: ['expense', 'income']
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      onChanged: (value) => setState(() => _budgetCategoryType = value!),
    );
  }

  Widget _buildBudgetItemNameField() {
    return TextFormField(
      controller: _budgetItemNameController,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter a name' : null,
    );
  }

  Widget _buildBudgetItemPlannedAmountField() {
    return TextFormField(
      controller: _budgetItemPlannedAmountController,
      decoration: InputDecoration(labelText: 'Planned Amount'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter planned amount' : null,
    );
  }

  Widget _buildBudgetItemCategoryField() {
    return TextFormField(
      controller: _budgetItemCategoryController,
      decoration: InputDecoration(labelText: 'Category'),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter category' : null,
    );
  }

  Widget _buildBudgetItemCategoryTypeField() {
    return DropdownButtonFormField<String>(
      value: _budgetItemCategoryType,
      decoration: InputDecoration(labelText: 'Category Type'),
      items: ['expense', 'income']
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      onChanged: (value) => setState(() => _budgetItemCategoryType = value!),
    );
  }

  Widget _buildBudgetItemDescriptionField() {
    return TextFormField(
      controller: _budgetItemDescriptionController,
      decoration: InputDecoration(labelText: 'Description'),
      maxLines: 3,
    );
  }

  Widget _buildSpentAmountField() {
    return TextFormField(
      controller: _spentAmountController,
      decoration: InputDecoration(labelText: 'Spent Amount'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter spent amount' : null,
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
                    'Loading budgets...',
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
                    Tab(text: 'Budgets'),
                    Tab(text: 'Budget Items'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBudgetsTab(),
                      _buildBudgetItemsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addBudget,
              backgroundColor: Color(0xFF72140C),
              child: Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Budget',
            )
          : null,
    );
  }

  Widget _buildBudgetsTab() {
    return _budgets.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No budgets found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your first budget to get started',
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
              itemCount: _budgets.length,
              itemBuilder: (context, index) {
                final budget = _budgets[index];
                final items = _budgetItems[budget['id']] ?? [];

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
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF72140C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.pie_chart,
                                  color: Color(0xFF72140C),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      budget['name'] ?? 'Unnamed Budget',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${budget['time_period'] ?? 'N/A'} • ${budget['category_type'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _viewBudgetDetails(budget);
                                  } else if (value == 'edit') {
                                    _editBudget(budget['id']);
                                  } else if (value == 'add_item') {
                                    _addBudgetItem(budget['id']);
                                  } else if (value == 'delete') {
                                    _deleteBudget(budget['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility,
                                            size: 18, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit,
                                            size: 18, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'add_item',
                                    child: Row(
                                      children: [
                                        Icon(Icons.add, size: 18),
                                        SizedBox(width: 8),
                                        Text('Add Item'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (budget['description'] != null) ...[
                            SizedBox(height: 12),
                            Text(
                              budget['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Planned: \$${budget['planned_amount'] ?? '0'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Spent: \$${budget['spent_amount'] ?? '0'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (budget['usage_percentage'] ?? 0) / 100.0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (budget['calculated_status'] == 'exceeded')
                                  ? Colors.red
                                  : Color(0xFF72140C),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${(budget['usage_percentage'] ?? 0).toStringAsFixed(1)}% used • \$${budget['remaining_amount'] ?? '0'} remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (items.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(
                              'Budget Items (${items.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF72140C),
                              ),
                            ),
                            SizedBox(height: 8),
                            ...items.take(3).map((item) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Unnamed Item',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        '\$${(double.tryParse(item['planned_amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            if (items.length > 3)
                              Text(
                                '...and ${items.length - 3} more items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildBudgetItemsTab() {
    final allItems = _budgetItems.values.expand((items) => items).toList();

    return allItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No budget items found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add items to your budgets to get started',
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
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                final plannedAmount = double.tryParse(
                        item['planned_amount']?.toString() ?? '0') ??
                    0.0;
                final spentAmount =
                    double.tryParse(item['spent_amount']?.toString() ?? '0') ??
                        0.0;
                final progress = plannedAmount > 0
                    ? (spentAmount / plannedAmount) * 100
                    : 0.0;

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
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: progress > 100
                              ? Colors.red.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          progress > 100 ? Icons.warning : Icons.list_alt,
                          color: progress > 100 ? Colors.red : Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(item['name'] ?? 'Unnamed Item'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${item['category'] ?? 'N/A'} • ${item['category_type'] ?? 'N/A'}'),
                          Text(
                              'Planned: \$${plannedAmount.toStringAsFixed(2)} • Spent: \$${spentAmount.toStringAsFixed(2)}'),
                          Text(
                              '${progress.toStringAsFixed(1)}% • ${progress > 100 ? 'Over Budget' : 'Within Budget'}'),
                          if (item['description'] != null)
                            Text(item['description']),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'update_spent') {
                            _updateBudgetItemSpentAmount(item['id']);
                          } else if (value == 'delete') {
                            _deleteBudgetItem(item['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'update_spent',
                            child: ListTile(
                              leading: Icon(Icons.edit, color: Colors.blue),
                              title: Text('Update Spent'),
                            ),
                          ),
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
