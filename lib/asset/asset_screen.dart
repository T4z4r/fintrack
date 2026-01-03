import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/api.dart';

class AssetScreen extends StatefulWidget {
  @override
  _AssetScreenState createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final Api _api = Api();
  List<dynamic> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    try {
      final response = await _api.getAssets();
      if (response.statusCode == 200) {
        setState(() {
          _assets = json.decode(response.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
        onPressed: () {
          // Add asset
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
