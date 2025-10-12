import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../models/address.dart';
import '../utils/constants.dart';
import 'map_picker_screen.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController(text: "Home");
  final _addrController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _loading = false;

  @override
  void dispose() {
    _labelController.dispose();
    _addrController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapPickerScreen()),
    );
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        _lat = res['lat'];
        _lng = res['lng'];
        _addrController.text = res['address'] ?? "${_lat}, ${_lng}";
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please pick location on map.")));
      return;
    }
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.accessTokenKey) ?? '';
    final address = AddressModel(
      label: _labelController.text.trim(),
      addressLine: _addrController.text.trim(),
      latitude: _lat!,
      longitude: _lng!,
      isDefault: false,
    );
    try {
      await LocationService.createAddress(token, address);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _addrController.text = "${pos.latitude}, ${pos.longitude}";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Address")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _labelController,
                    decoration: InputDecoration(labelText: "Label"),
                  ),
                  TextFormField(
                    controller: _addrController,
                    decoration: InputDecoration(labelText: "Address"),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: Icon(Icons.my_location),
                        label: Text("Use Current"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickOnMap,
                        icon: Icon(Icons.map),
                        label: Text("Pick on map"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? CircularProgressIndicator()
                        : const Text("Save Address"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
