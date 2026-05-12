class UserModel {
  final int     id;
  final String  username;
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
    required this.username,
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
    return UserModel(
      id:             json['id'],
      username:       json['username']       ?? '',
      email:          json['email']          ?? '',
      firstName:      json['first_name']     ?? '',
      lastName:       json['last_name']      ?? '',
      fullName:       json['full_name']      ?? '',
      phone:          json['phone']          ?? '',
      role:           json['role']           ?? 'driver',
      profilePhoto:   json['profile_photo'],
      licenseNumber:  json['license_number'],
      licenseExpiry:  json['license_expiry'],
      isActive:       json['is_active']      ?? true,
    );
  }

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
