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
          });

          // Fetch budget items for each budget
          for (var budget in _budgets) {
            final itemsResponse =
                await _api.getBudgetItemsForBudget(budget['id']);
            if (itemsResponse.statusCode == 200) {
              final itemsData = json.decode(itemsResponse.body);
              if (itemsData['success'] == true) {
                setState(() {
                  _budgetItems[budget['id']] =
                      List<Map<String, dynamic>>.from(itemsData['data']);
                });
              }
            }
          }
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
                                  if (value == 'add_item') {
                                    _addBudgetItem(budget['id']);
                                  } else if (value == 'delete') {
                                    _deleteBudget(budget['id']);
                                  }
                                },
                                itemBuilder: (context) => [
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
