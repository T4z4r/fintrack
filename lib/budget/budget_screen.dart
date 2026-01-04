import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';

class BudgetScreen extends StatefulWidget {
  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  late Api _api;
  List<Map<String, dynamic>> _budgets = [];
  Map<int, List<Map<String, dynamic>>> _budgetItems = {};
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
      final budgetsResponse = await _api.getBudgets();
      if (budgetsResponse.statusCode == 200) {
        final budgetsData = json.decode(budgetsResponse.body);
        if (budgetsData['success'] == true) {
          setState(() {
            _budgets = List<Map<String, dynamic>>.from(budgetsData['data']);
          });
          
          // Fetch budget items for each budget
          for (var budget in _budgets) {
            final itemsResponse = await _api.getBudgetItemsForBudget(budget['id']);
            if (itemsResponse.statusCode == 200) {
              final itemsData = json.decode(itemsResponse.body);
              if (itemsData['success'] == true) {
                setState(() {
                  _budgetItems[budget['id']] = List<Map<String, dynamic>>.from(itemsData['data']);
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BudgetFormDialog(),
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BudgetItemFormDialog(budgetId: budgetId),
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UpdateSpentAmountDialog(),
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
        content: Text('Are you sure you want to delete this budget? This will also delete all budget items.'),
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
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                final plannedAmount = double.tryParse(item['planned_amount']?.toString() ?? '0') ?? 0.0;
                final spentAmount = double.tryParse(item['spent_amount']?.toString() ?? '0') ?? 0.0;
                final progress = plannedAmount > 0 ? (spentAmount / plannedAmount) * 100 : 0.0;
                
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                color: progress > 100 ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                progress > 100 ? Icons.warning : Icons.list_alt,
                                color: progress > 100 ? Colors.red : Colors.blue,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Unnamed Item',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${item['category'] ?? 'N/A'} • ${item['category_type'] ?? 'N/A'}',
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
                                if (value == 'update_spent') {
                                  _updateBudgetItemSpentAmount(item['id']);
                                } else if (value == 'delete') {
                                  _deleteBudgetItem(item['id']);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'update_spent',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Update Spent'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (item['description'] != null) ...[
                          SizedBox(height: 12),
                          Text(
                            item['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Planned: \$${plannedAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Spent: \$${spentAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: progress > 100 ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${progress.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: progress > 100 ? Colors.red : Colors.blue,
                                  ),
                                ),
                                Text(
                                  progress > 100 ? 'Over Budget' : 'Within Budget',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: progress > 100 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress > 100 ? 1.0 : progress / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 100 ? Colors.red : Colors.blue,
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
}

class BudgetFormDialog extends StatefulWidget {
  @override
  _BudgetFormDialogState createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _timePeriod = 'monthly';
  String _categoryType = 'expense';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Budget'),
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
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: _timePeriod,
                decoration: InputDecoration(labelText: 'Time Period'),
                items: ['monthly', 'yearly', 'weekly']
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _timePeriod = value!),
              ),
              DropdownButtonFormField<String>(
                value: _categoryType,
                decoration: InputDecoration(labelText: 'Category Type'),
                items: ['expense', 'income']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _categoryType = value!),
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
                'description': _descriptionController.text,
                'time_period': _timePeriod,
                'category_type': _categoryType,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class BudgetItemFormDialog extends StatefulWidget {
  final int budgetId;

  const BudgetItemFormDialog({Key? key, required this.budgetId}) : super(key: key);

  @override
  _BudgetItemFormDialogState createState() => _BudgetItemFormDialogState();
}

class _BudgetItemFormDialogState extends State<BudgetItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plannedAmountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _categoryType = 'expense';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Budget Item'),
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
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _plannedAmountController,
                decoration: InputDecoration(labelText: 'Planned Amount'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter planned amount' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter category' : null,
              ),
              DropdownButtonFormField<String>(
                value: _categoryType,
                decoration: InputDecoration(labelText: 'Category Type'),
                items: ['expense', 'income']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _categoryType = value!),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
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
                'budget_id': widget.budgetId,
                'name': _nameController.text,
                'planned_amount': double.parse(_plannedAmountController.text),
                'category_type': _categoryType,
                'category': _categoryController.text,
                'description': _descriptionController.text,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class UpdateSpentAmountDialog extends StatefulWidget {
  @override
  _UpdateSpentAmountDialogState createState() => _UpdateSpentAmountDialogState();
}

class _UpdateSpentAmountDialogState extends State<UpdateSpentAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _spentAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Spent Amount'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _spentAmountController,
          decoration: InputDecoration(labelText: 'Spent Amount'),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter spent amount' : null,
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
                'spent_amount': double.parse(_spentAmountController.text),
              });
            }
          },
          child: Text('Update'),
        ),
      ],
    );
  }
}