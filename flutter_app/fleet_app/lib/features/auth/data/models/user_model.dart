class UserModel {
  final String  id;
  final String  email;
  final String  firstName;
  final String  lastName;
  final String  fullName;
  final String  phone;
  final String  role;
  final String? profilePhoto;
  final String? licenseNumber;
  final String? licenseExpiry;
  final bool    isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.role,
    this.profilePhoto,
    this.licenseNumber,
    this.licenseExpiry,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final first = json['first_name'] ?? '';
    final last  = json['last_name']  ?? '';
    return UserModel(
      id:            json['id']            ?? '',
      email:         json['email']         ?? '',
      firstName:     first,
      lastName:      last,
      fullName:      json['full_name']     ?? '$first $last'.trim(),
      phone:         json['phone']         ?? '',
      role:          json['role']          ?? 'driver',
      profilePhoto:  json['profile_photo'],
      licenseNumber: json['license_number'],
      licenseExpiry: json['license_expiry'],
      isActive:      json['is_active']     ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'email':         email,
    'first_name':    firstName,
    'last_name':     lastName,
    'full_name':     fullName,
    'phone':         phone,
    'role':          role,
    'profile_photo': profilePhoto,
    'license_number': licenseNumber,
    'license_expiry': licenseExpiry,
    'is_active':     isActive,
  };

  bool get isOwner        => role == 'owner';
  bool get isAdmin        => role == 'admin';
  bool get isFleetManager => role == 'fleet_manager';
  bool get isDriver       => role == 'driver';

  String get roleLabel {
    switch (role) {
      case 'owner':         return 'Owner';
      case 'admin':         return 'Admin';
      case 'fleet_manager': return 'Fleet Manager';
      case 'driver':        return 'Driver';
      default:              return 'Unknown';
    }
  }
}
