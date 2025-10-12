import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/address.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'address_list_screen.dart';
import 'add_address_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  // User location state
  bool _locationPermissionGranted = false;
  bool _checkingLocation = true;
  Position? _currentPosition;
  AddressModel? _selectedAddress;
  List<AddressModel> _savedAddresses = [];

  // Booking form state
  String? _vehicleType;
  DateTime? _selectedDate;
  String? _timeSlot;
  final TextEditingController _notesController = TextEditingController();
  bool _loading = false;

  List<String> _vehicleOptions = ["car", "bike"];
  List<String> _timeSlots = [
    "05:00 AM",
    "06:00 AM",
    "07:00 AM",
    "08:00 AM",
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "01:00 PM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM",
    "06:00 PM",
    "07:00 PM",
    "08:00 PM",
    "09:00 PM",
    "10:00 PM",
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocationAndAddresses();
  }

  Future<void> _initializeLocationAndAddresses() async {
    setState(() => _checkingLocation = true);

    try {
      // Check location permission
      await _checkLocationPermission();

      // Load saved addresses
      await _loadSavedAddresses();

      // Get current location if permission granted
      if (_locationPermissionGranted) {
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
      _showErrorSnackBar('Error setting up location: $e');
    }

    setState(() => _checkingLocation = false);
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() => _locationPermissionGranted = true);
      }
    } catch (e) {
      print('Location permission error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print('Current location error: $e');
    }
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final addresses = await ApiService.getUserAddresses();
      setState(() => _savedAddresses = addresses);

      // Auto-select first address if available
      if (addresses.isNotEmpty && _selectedAddress == null) {
        setState(() => _selectedAddress = addresses.first);
      }
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Location Service Required'),
        content: Text(
          'Please enable location services to get your current location for booking service.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddressSelection();
            },
            child: Text('Use Saved Address'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Location Permission Required'),
        content: Text(
          'Location permission is required to provide service at your location. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddressSelection();
            },
            child: Text('Use Saved Address'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showAddressSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Service Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Current Location Option
            if (_locationPermissionGranted && _currentPosition != null)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.my_location,
                    color: AppColors.primaryColor,
                  ),
                  title: Text('Current Location'),
                  subtitle: Text('Use your current GPS location'),
                  trailing: _selectedAddress == null
                      ? Icon(Icons.check, color: AppColors.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedAddress = null);
                    Navigator.pop(context);
                  },
                ),
              ),

            SizedBox(height: 8),

            // Saved Addresses
            Text(
              'Saved Addresses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            Expanded(
              child: _savedAddresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No saved addresses'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddAddressScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadSavedAddresses();
                              }
                            },
                            child: Text('Add Address'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _savedAddresses.length,
                      itemBuilder: (context, index) {
                        final address = _savedAddresses[index];
                        final isSelected = _selectedAddress?.id == address.id;

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              _getAddressIcon(address.label),
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                            ),
                            title: Text(address.label),
                            subtitle: Text(address.addressLine),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.primaryColor,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _selectedAddress = address);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Add New Address Button
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddAddressScreen()),
                  );
                  if (result == true) {
                    _loadSavedAddresses();
                  }
                },
                icon: Icon(Icons.add),
                label: Text('Add New Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'other':
      default:
        return Icons.location_on;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    // Check if location is selected
    if (_selectedAddress == null && _currentPosition == null) {
      _showErrorSnackBar("Please select a service location");
      _showAddressSelection();
      return;
    }

    setState(() => _loading = true);

    // 🔧 FIX: Proper booking data format with location
    final bookingData = {
      "vehicle_type": _vehicleType,
      "date": _selectedDate!.toIso8601String().split(
        "T",
      )[0], // ✅ Already correct
      "time_slot": _timeSlot,
      "notes": _notesController.text,

      // 🆕 ADD: Location data (get from location service or user selection)
      "latitude": 18.524609, // ✅ 6 decimal places max
      "longitude": 73.878624, // ✅ 6 decimal places max
      "service_address": "Current Location", // Or get from location service
    };

    try {
      final response = await ApiService.createBooking(bookingData);
      setState(() => _loading = false);

      if (response.containsKey("id")) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Booking successful!")));
        // Clear form
        setState(() {
          _vehicleType = null;
          _selectedDate = null;
          _timeSlot = null;
          _notesController.clear();
        });
      } else {
        final errorMessage = response['error']?.toString() ?? 'Booking failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _showBookingSuccessDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Booking Confirmed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: #${booking["id"]}'),
            SizedBox(height: 8),
            Text('Vehicle: ${_vehicleType?.toUpperCase()}'),
            Text('Date: ${_selectedDate?.toLocal().toString().split(" ")}'),
            Text('Time: $_timeSlot'),
            if (_selectedAddress != null)
              Text('Location: ${_selectedAddress!.label}')
            else
              Text('Location: Current Location'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLocation) {
      return Scaffold(
        appBar: AppBar(title: Text("Auto Care")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up location services...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Service"),
        actions: [
          IconButton(
            onPressed: () async {
              await ApiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Service Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      if (_selectedAddress != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedAddress!.label,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(_selectedAddress!.addressLine),
                            ],
                          ),
                        )
                      else if (_currentPosition != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                      '${_currentPosition!.longitude.toStringAsFixed(4)}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'No location selected',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddressSelection,
                          icon: Icon(Icons.location_searching),
                          label: Text('Select Location'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Booking Form
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Vehicle Type
                      DropdownButtonFormField<String>(
                        value: _vehicleType,
                        hint: Text("Select Vehicle Type"),
                        items: _vehicleOptions
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _vehicleType = val),
                        validator: (val) => val == null ? "Required" : null,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Date Selection
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Service Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? "Select Service Date"
                                : _formatDate(_selectedDate!),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Time Slot
                      DropdownButtonFormField<String>(
                        value: _timeSlot,
                        hint: Text("Select Time Slot"),
                        items: _timeSlots
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _timeSlot = val),
                        validator: (val) => val == null ? "Required" : null,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: "Special Instructions (Optional)",
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Book Now Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitBooking,
                  child: _loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text("Booking..."),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_online),
                            SizedBox(width: 8),
                            Text("Book Now"),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Info Card
              Card(
                color: AppColors.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Our team will arrive at your selected location at the chosen time slot.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
