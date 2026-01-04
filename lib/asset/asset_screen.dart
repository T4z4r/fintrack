import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/custom_loader.dart';
import '../widgets/bottom_sheet_form.dart';

class AssetScreen extends StatefulWidget {
  @override
  _AssetScreenState createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  late Api _api;
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Form controllers for bottom sheet
  final _assetFormKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _assetValueController = TextEditingController();
  final _assetAcquisitionDateController = TextEditingController();
  String _assetCategory = 'Vehicle';

  @override
  void initState() {
    super.initState();
    // Get the API instance from AuthProvider
    _api = Provider.of<AuthProvider>(context, listen: false).api;
    _fetchAssets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _assetNameController.dispose();
    _assetValueController.dispose();
    _assetAcquisitionDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssets() async {
    try {
      final response = await _api.getAssets();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _assets = List<Map<String, dynamic>>.from(data['data']);
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

  Future<void> _addAsset() async {
    // Clear form
    _assetNameController.clear();
    _assetValueController.clear();
    _assetAcquisitionDateController.clear();
    _assetCategory = 'Vehicle';

    final result = await BottomSheetForm.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Asset',
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
      formKey: _assetFormKey,
      formFields: [
        _buildAssetNameField(),
        SizedBox(height: 16),
        _buildAssetCategoryField(),
        SizedBox(height: 16),
        _buildAssetValueField(),
        SizedBox(height: 16),
        _buildAssetAcquisitionDateField(),
      ],
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        Navigator.of(context).pop({
          'name': _assetNameController.text,
          'category': _assetCategory,
          'value': double.parse(_assetValueController.text),
          'acquisition_date': _assetAcquisitionDateController.text,
        });
      },
      submitText: 'Add Asset',
    );

    if (result != null) {
      try {
        final response = await _api.createAsset(result);
        if (response.statusCode == 201) {
          _fetchAssets();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Asset created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create asset')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAsset(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Asset'),
        content: Text('Are you sure you want to delete this asset?'),
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
        final response = await _api.deleteAsset(id);
        if (response.statusCode == 200) {
          _fetchAssets();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Asset deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete asset')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewAssetDetails(Map<String, dynamic> asset) async {
    final value = double.tryParse(asset['value']?.toString() ?? '0') ?? 0.0;

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
                      _getAssetIcon(asset['category']),
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
                          asset['name'] ?? 'Unnamed Asset',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF72140C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete asset information and details',
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
                    // Value highlight
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
                            '\$${value.toStringAsFixed(2)}',
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
                    _buildDetailSection('Asset Information', [
                      _buildDetailRow(
                          'Name', asset['name'] ?? 'N/A', Icons.business),
                      _buildDetailRow('Category', asset['category'] ?? 'N/A',
                          Icons.category),
                      _buildDetailRow('Value', '\$${value.toStringAsFixed(2)}',
                          Icons.attach_money),
                      _buildDetailRow(
                          'Acquisition Date',
                          asset['acquisition_date'] ?? 'N/A',
                          Icons.calendar_today),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created', asset['created_at'] ?? 'N/A',
                          Icons.access_time),
                      _buildDetailRow('Updated', asset['updated_at'] ?? 'N/A',
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

  Future<void> _editAsset(int id) async {
    try {
      final response = await _api.getAsset(id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final asset = data['data'];
          // Pre-fill controllers
          _assetNameController.text = asset['name'] ?? '';
          _assetValueController.text = asset['value']?.toString() ?? '';
          _assetAcquisitionDateController.text =
              asset['acquisition_date'] ?? '';
          _assetCategory = asset['category'] ?? 'Vehicle';

          final result = await BottomSheetForm.show<Map<String, dynamic>>(
            context: context,
            title: 'Edit Asset',
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
            formKey: _assetFormKey,
            formFields: [
              _buildAssetNameField(),
              SizedBox(height: 16),
              _buildAssetCategoryField(),
              SizedBox(height: 16),
              _buildAssetValueField(),
              SizedBox(height: 16),
              _buildAssetAcquisitionDateField(),
            ],
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: () {
              Navigator.of(context).pop({
                'name': _assetNameController.text,
                'category': _assetCategory,
                'value': double.parse(_assetValueController.text),
                'acquisition_date': _assetAcquisitionDateController.text,
              });
            },
            submitText: 'Update Asset',
          );

          if (result != null) {
            final updateResponse = await _api.updateAsset(id, result);
            if (updateResponse.statusCode == 200) {
              _fetchAssets();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Asset updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update asset')),
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

  IconData _getAssetIcon(String? category) {
    switch (category) {
      case 'Real Estate':
        return Icons.home;
      case 'Vehicle':
        return Icons.directions_car;
      case 'Jewelry':
        return Icons.wallet_giftcard;
      case 'Other':
      default:
        return Icons.inventory;
    }
  }

  Color _getAssetColor(String? category) {
    switch (category) {
      case 'Real Estate':
        return Colors.blue;
      case 'Vehicle':
        return Colors.green;
      case 'Jewelry':
        return Colors.purple;
      case 'Other':
      default:
        return Colors.orange;
    }
  }

  Widget _buildAssetNameField() {
    return TextFormField(
      controller: _assetNameController,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) => value?.isEmpty ?? true ? 'Please enter name' : null,
    );
  }

  Widget _buildAssetCategoryField() {
    return DropdownButtonFormField<String>(
      value: _assetCategory,
      decoration: InputDecoration(labelText: 'Category'),
      items: ['Vehicle', 'Jewelry', 'Real Estate', 'Other']
          .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
          .toList(),
      onChanged: (value) => setState(() => _assetCategory = value!),
    );
  }

  Widget _buildAssetValueField() {
    return TextFormField(
      controller: _assetValueController,
      decoration: InputDecoration(labelText: 'Value'),
      keyboardType: TextInputType.number,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter value' : null,
    );
  }

  Widget _buildAssetAcquisitionDateField() {
    return TextFormField(
      controller: _assetAcquisitionDateController,
      decoration: InputDecoration(labelText: 'Acquisition Date (YYYY-MM-DD)'),
      validator: (value) => value?.isEmpty ?? true ? 'Please enter date' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssets = _assets.where((asset) {
      final query = _searchQuery.toLowerCase();
      final name = (asset['name'] ?? '').toLowerCase();
      final category = (asset['category'] ?? '').toLowerCase();
      return name.contains(query) || category.contains(query);
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
                    'Loading assets...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : filteredAssets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No assets found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first asset to track your wealth',
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
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search Asset ',
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
                            onPressed: () => _addAsset(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF72140C),
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: Icon(Icons.add,
                                color: Theme.of(context).colorScheme.onPrimary),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchAssets,
                        color: Color(0xFF72140C),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredAssets.length,
                          itemBuilder: (context, index) {
                            final asset = filteredAssets[index];
                            final value = double.tryParse(
                                    asset['value']?.toString() ?? '0') ??
                                0.0;
                            final icon = _getAssetIcon(asset['category']);
                            final color = _getAssetColor(asset['category']);

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
                                      icon,
                                      color: Color(0xFF72140C),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(asset['name'] ?? 'Unnamed Asset'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${asset['category'] ?? 'N/A'} • Acquired: ${asset['acquisition_date'] ?? 'N/A'}'),
                                      Text('\$${value.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        _viewAssetDetails(asset);
                                      } else if (value == 'edit') {
                                        _editAsset(asset['id']);
                                      } else if (value == 'delete') {
                                        _deleteAsset(asset['id']);
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
    );
  }
}
