import 'package:flutter/material.dart';
import '../core/database_helper.dart';
import '../core/api.dart';

class AssetScreen extends StatefulWidget {
  @override
  _AssetScreenState createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final Api _api = Api();
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    _syncAssets();
  }

  Future<void> _fetchAssets() async {
    try {
      _assets = await _db.getAssets();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncAssets() async {
    await _api.syncAssets();
  }

  Future<void> _addAsset() async {
    await _db.insertAsset({
      'name': 'Test Asset',
      'type': 'property',
      'value': 10000.0,
      'acquisition_date': '2024-01-01',
      'description': 'Test Asset',
      'synced': 0,
    });
    _fetchAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asset')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final asset = _assets[index];
                return ListTile(
                  title: Text(asset['name'] ?? 'No name'),
                  subtitle: Text('Value: ${asset['value']}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAsset,
        child: Icon(Icons.add),
      ),
    );
  }
}
