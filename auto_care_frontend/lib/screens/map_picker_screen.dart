import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  LatLng _center = const LatLng(28.6139, 77.2090); // fallback (New Delhi)
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _initPos();
  }

  Future<void> _initPos() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {}
  }

  void _onTap(LatLng p) {
    setState(() {
      _picked = p;
    });
  }

  void _confirm() {
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tap map to pick a location")),
      );
      return;
    }
    Navigator.pop(context, {
      'lat': _picked!.latitude,
      'lng': _picked!.longitude,
      'address': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _controller = c,
            onTap: _onTap,
            markers: _picked == null
                ? {}
                : {Marker(markerId: MarkerId('pick'), position: _picked!)},
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirm,
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}
