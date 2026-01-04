import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../auth/auth_provider.dart';
import '../widgets/custom_loader.dart';

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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AssetFormDialog(),
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

  IconData _getAssetIcon(String? type) {
    switch (type) {
      case 'real_estate':
        return Icons.home;
      case 'vehicle':
        return Icons.directions_car;
      case 'jewelry':
        return Icons.wallet_giftcard;
      case 'other':
      default:
        return Icons.inventory;
    }
  }

  Color _getAssetColor(String? type) {
    switch (type) {
      case 'real_estate':
        return Colors.blue;
      case 'vehicle':
        return Colors.green;
      case 'jewelry':
        return Colors.purple;
      case 'other':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssets = _assets.where((asset) {
      final query = _searchQuery.toLowerCase();
      final name = (asset['name'] ?? '').toLowerCase();
      final type = (asset['type'] ?? '').toLowerCase();
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
                      padding: EdgeInsets.all(8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search assets',
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
                            final icon = _getAssetIcon(asset['type']);
                            final color = _getAssetColor(asset['type']);

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
                                          '${asset['type']?.replaceAll('_', ' ') ?? 'N/A'} • Acquired: ${asset['acquisition_date'] ?? 'N/A'}'),
                                      Text('\$${value.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteAsset(asset['id']);
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
        onPressed: _addAsset,
        backgroundColor: Color(0xFF72140C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Asset',
      ),
    );
  }
}

class AssetFormDialog extends StatefulWidget {
  @override
  _AssetFormDialogState createState() => _AssetFormDialogState();
}

class _AssetFormDialogState extends State<AssetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _acquisitionDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'real_estate';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Asset'),
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
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: 'Type'),
                items: ['real_estate', 'vehicle', 'jewelry', 'other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(labelText: 'Value'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter value' : null,
              ),
              TextFormField(
                controller: _acquisitionDateController,
                decoration:
                    InputDecoration(labelText: 'Acquisition Date (YYYY-MM-DD)'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter date' : null,
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
                'name': _nameController.text,
                'type': _type,
                'value': double.parse(_valueController.text),
                'acquisition_date': _acquisitionDateController.text,
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
