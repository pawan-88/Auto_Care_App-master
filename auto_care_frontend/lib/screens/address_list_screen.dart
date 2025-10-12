import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../models/address.dart';
import 'add_address_screen.dart';
import '../utils/constants.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({Key? key}) : super(key: key);

  @override
  _AddressListScreenState createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<AddressModel> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.accessTokenKey) ?? '';
    try {
      final list = await LocationService.fetchAddresses(token);
      setState(() => _addresses = list);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onAdd() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAddressScreen()),
    );
    if (created == true) _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Addresses")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _addresses.length,
              itemBuilder: (ctx, i) {
                final a = _addresses[i];
                return ListTile(
                  title: Text(a.label),
                  subtitle: Text(a.addressLine),
                  trailing: a.isDefault ? const Icon(Icons.star) : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
