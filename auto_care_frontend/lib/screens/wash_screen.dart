import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/address.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'address_selection_screen.dart';
import 'booking_confirmation_screen.dart';

class WashScreen extends StatefulWidget {
  final String? initialVehicle;

  const WashScreen({Key? key, this.initialVehicle}) : super(key: key);

  @override
  State<WashScreen> createState() => _WashScreenState();
}

class _WashScreenState extends State<WashScreen> {
  int _currentStep = 0;

  // Step 1: Vehicle Selection
  String? _selectedVehicle;

  // Step 2: Service Selection
  String? _selectedService;
  final List<String> _selectedAddons = [];

  // Step 3: Date & Time Selection
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  AddressModel? _selectedAddress;
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      _selectedVehicle = widget.initialVehicle;
      _currentStep = 1; // Skip vehicle selection
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Services data
  final Map<String, List<Map<String, dynamic>>> _services = {
    'car': [
      {
        'id': 'basic_car',
        'name': 'Basic Wash',
        'price': 299,
        'duration': '30-45 mins',
        'features': ['Exterior wash', 'Tire cleaning', 'Basic interior wipe'],
      },
      {
        'id': 'premium_car',
        'name': 'Premium Wash',
        'price': 499,
        'duration': '60-90 mins',
        'features': [
          'Everything in Basic',
          'Interior vacuum',
          'Dashboard polish',
          'Window cleaning',
        ],
      },
      {
        'id': 'deluxe_car',
        'name': 'Deluxe Detailing',
        'price': 1499,
        'duration': '2-3 hours',
        'features': [
          'Everything in Premium',
          'Wax & polish',
          'Engine cleaning',
          'Headlight restoration',
        ],
      },
    ],
    'bike': [
      {
        'id': 'basic_bike',
        'name': 'Basic Wash',
        'price': 149,
        'duration': '20-30 mins',
        'features': ['Complete bike wash', 'Chain cleaning', 'Basic polish'],
      },
      {
        'id': 'premium_bike',
        'name': 'Premium Wash',
        'price': 299,
        'duration': '45-60 mins',
        'features': [
          'Everything in Basic',
          'Engine degreasing',
          'Chrome polish',
          'Seat cleaning',
        ],
      },
    ],
  };

  final List<Map<String, dynamic>> _addons = [
    {'id': 'wax_polish', 'name': 'Wax & Polish', 'price': 200},
    {'id': 'ac_vent', 'name': 'AC Vent Cleaning', 'price': 150},
    {'id': 'perfume', 'name': 'Car Perfume', 'price': 100},
    {'id': 'tire_shine', 'name': 'Tire Shine', 'price': 80},
  ];

  final List<String> _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  int _getTotalPrice() {
    int total = 0;

    if (_selectedService != null) {
      final service = _services[_selectedVehicle]!.firstWhere(
        (s) => s['id'] == _selectedService,
      );
      total += service['price'] as int;
    }

    for (var addonId in _selectedAddons) {
      final addon = _addons.firstWhere((a) => a['id'] == addonId);
      total += addon['price'] as int;
    }

    return total;
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final bookingData = {
      'vehicle_type': _selectedVehicle,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'time_slot': _selectedTimeSlot,
      'notes': _notesController.text.trim(),
    };

    final response = await ApiService.createBooking(bookingData);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error']),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BookingConfirmationScreen(bookingData: response),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.bookService),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Vehicle'),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Service'),
          _buildStepLine(1),
          _buildStepIndicator(2, 'Schedule'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isActive
                ? AppColors.primaryColor
                : AppColors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.white : AppColors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.success : AppColors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildVehicleSelection();
      case 1:
        return _buildServiceSelection();
      case 2:
        return _buildScheduleSelection();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVehicleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Vehicle',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the vehicle type you want to service',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildVehicleCard(
            type: 'car',
            icon: Icons.directions_car,
            title: 'Car',
            subtitle: 'Starting from ₹299',
          ),
          const SizedBox(height: 16),
          _buildVehicleCard(
            type: 'bike',
            icon: Icons.two_wheeler,
            title: 'Bike / Scooter',
            subtitle: 'Starting from ₹149',
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedVehicle == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicle = type;
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : AppColors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 48,
                color: isSelected ? AppColors.primaryColor : AppColors.grey,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    if (_selectedVehicle == null) return const SizedBox();

    final services = _services[_selectedVehicle]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Service Package',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the service that best fits your needs',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...services.map((service) => _buildServiceCard(service)).toList(),
          const SizedBox(height: 24),
          Text(
            'Add-ons (Optional)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._addons.map((addon) => _buildAddonCard(addon)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isSelected = _selectedService == service['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedService = service['id'];
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service['duration'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${service['price']}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List<Widget>.from(
                (service['features'] as List).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddonCard(Map<String, dynamic> addon) {
    final isSelected = _selectedAddons.contains(addon['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedAddons.remove(addon['id']);
            } else {
              _selectedAddons.add(addon['id']);
            }
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedAddons.add(addon['id']);
                    } else {
                      _selectedAddons.remove(addon['id']);
                    }
                  });
                },
                activeColor: AppColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  addon['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '+₹${addon['price']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Your Service',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Address Selection
          _buildSectionTitle('Service Location'),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final address = await Navigator.push<AddressModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressSelectionScreen(),
                ),
              );
              if (address != null) {
                setState(() {
                  _selectedAddress = address;
                });
              }
            },
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                border: Border.all(
                  color: _selectedAddress != null
                      ? AppColors.primaryColor
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedAddress != null
                        ? Icons.location_on
                        : Icons.location_on_outlined,
                    color: _selectedAddress != null
                        ? AppColors.primaryColor
                        : AppColors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedAddress?.getShortAddress() ?? 'Select Address',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedAddress != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Date Selection
          _buildSectionTitle('Select Date'),
          const SizedBox(height: 12),
          _buildDateSelector(),
          const SizedBox(height: 24),

          // Time Slot Selection
          _buildSectionTitle('Select Time Slot'),
          const SizedBox(height: 12),
          _buildTimeSlotGrid(),
          const SizedBox(height: 24),

          // Special Instructions
          _buildSectionTitle('Special Instructions (Optional)'),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special instructions for the service provider...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Next 14 days
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected =
              _selectedDate != null &&
              _selectedDate!.day == date.day &&
              _selectedDate!.month == date.month;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : AppColors.white,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
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

  Widget _buildTimeSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = _timeSlots[index];
        final isSelected = _selectedTimeSlot == timeSlot;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedTimeSlot = timeSlot;
            });
          },
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : AppColors.white,
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusMedium,
              ),
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : AppColors.divider,
              ),
            ),
            child: Center(
              child: Text(
                timeSlot,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    bool canProceed = false;

    switch (_currentStep) {
      case 0:
        canProceed = _selectedVehicle != null;
        break;
      case 1:
        canProceed = _selectedService != null;
        break;
      case 2:
        canProceed =
            _selectedDate != null &&
            _selectedTimeSlot != null &&
            _selectedAddress != null;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStep == 1 || _currentStep == 2) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${_getTotalPrice()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            CustomButton(
              text: _currentStep == 2 ? 'Confirm Booking' : 'Continue',
              onPressed: canProceed
                  ? () {
                      if (_currentStep == 2) {
                        _confirmBooking();
                      } else {
                        setState(() {
                          _currentStep++;
                        });
                      }
                    }
                  : null,
              isLoading: _isLoading,
              icon: _currentStep == 2
                  ? Icons.check_circle
                  : Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}
