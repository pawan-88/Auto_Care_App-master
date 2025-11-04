class ServiceProvider {
  final int id;
  final String employeeId;
  final String fullName;
  final String specialization;
  final bool isAvailable;

  ServiceProvider({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.specialization,
    required this.isAvailable,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'],
      employeeId: json['employee_id'],
      fullName: json['full_name'],
      specialization: json['specialization'],
      isAvailable: json['is_available'],
    );
  }
}
