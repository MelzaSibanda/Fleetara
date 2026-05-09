
class VehicleModel {
  final int     id;
  final String  registrationNumber;
  final String  make;
  final String  model;
  final int     year;
  final String  status;
  final int     odometer;
  final int     nextServiceKm;
  final String  licenseExpiry;
  final String  insuranceExpiry;
  final bool    serviceDue;
  final int     kmUntilService;
  final String? photo;

  VehicleModel({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.status,
    required this.odometer,
    required this.nextServiceKm,
    required this.licenseExpiry,
    required this.insuranceExpiry,
    required this.serviceDue,
    required this.kmUntilService,
    this.photo,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id:                 json['id'],
    registrationNumber: json['registration_number'] ?? '',
    make:               json['make']                ?? '',
    model:              json['model']               ?? '',
    year:               json['year']                ?? 0,
    status:             json['status']              ?? 'active',
    odometer:           json['odometer']            ?? 0,
    nextServiceKm:      json['next_service_km']     ?? 0,
    licenseExpiry:      json['license_expiry']      ?? '',
    insuranceExpiry:    json['insurance_expiry']    ?? '',
    serviceDue:         json['service_due']         ?? false,
    kmUntilService:     json['km_until_service']    ?? 0,
    photo:              json['photo'],
  );
}
