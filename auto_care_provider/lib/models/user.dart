class User {
  final String mobileNumber;
  final String name;
  User({required this.mobileNumber, required this.name});
  factory User.fromJson(Map<String, dynamic> json) =>
      User(mobileNumber: json['mobile_number'], name: json['name'] ?? '');
}
