class VehicleModel {
  final int     id;
  final String  type; // 'horse' or 'trailer'
  final String  registrationNumber;
  final String  make;
  final String  model;
  final int     year;
  final String  status;
  final int     odometer;
  final int     nextServiceKm;
  final int     serviceIntervalKm;
  final String  licenseExpiry;
  final String  insuranceExpiry;
  final bool    serviceDue;
  final int     kmUntilService;
  final String? notes;
  final String? photo;

  VehicleModel({
    required this.id,
    required this.type,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.status,
    required this.odometer,
    required this.nextServiceKm,
    required this.serviceIntervalKm,
    required this.licenseExpiry,
    required this.insuranceExpiry,
    required this.serviceDue,
    required this.kmUntilService,
    this.notes,
    this.photo,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json, {String type = 'horse'}) => VehicleModel(
    id:                 json['id'],
    type:               type,
    registrationNumber: json['registration_number'] ?? '',
    make:               json['make']                ?? '',
    model:              json['model']               ?? '',
    year:               json['year']                ?? 0,
    status:             json['status']              ?? 'active',
    odometer:           json['odometer']            ?? 0,
    nextServiceKm:      json['next_service_km']     ?? 0,
    serviceIntervalKm:  json['service_interval_km'] ?? 20000,
    licenseExpiry:      json['license_expiry']      ?? '',
    insuranceExpiry:    json['insurance_expiry']    ?? '',
    serviceDue:         json['service_due']         ?? false,
    kmUntilService:     json['km_until_service']    ?? 0,
    notes:              json['notes'],
    photo:              json['photo'],
  );
}
