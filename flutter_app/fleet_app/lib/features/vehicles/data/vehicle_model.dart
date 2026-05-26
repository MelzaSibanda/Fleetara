class VehicleModel {
  final String  id;
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

  factory VehicleModel.fromJson(Map<String, dynamic> json, {String type = 'horse'}) {
    final odometer          = (json['odometer']             ?? 0) as int;
    final nextServiceKm     = (json['next_service_km']      ?? 0) as int;
    final serviceIntervalKm = (json['service_interval_km']  ?? 20000) as int;
    final kmUntilService    = nextServiceKm > odometer
        ? nextServiceKm - odometer
        : (json['km_until_service'] ?? 0) as int;
    final serviceDue        = kmUntilService <= 0;

    return VehicleModel(
      id:                 json['id']?.toString()             ?? '',
      type:               json['type']                       ?? type,
      registrationNumber: json['registration_number']        ?? '',
      make:               json['make']                       ?? '',
      model:              json['model']                      ?? '',
      year:               (json['year']                      ?? 0) as int,
      status:             json['status']                     ?? 'active',
      odometer:           odometer,
      nextServiceKm:      nextServiceKm,
      serviceIntervalKm:  serviceIntervalKm,
      licenseExpiry:      json['license_expiry']             ?? '',
      insuranceExpiry:    json['insurance_expiry']           ?? '',
      serviceDue:         json['service_due']                ?? serviceDue,
      kmUntilService:     kmUntilService,
      notes:              json['notes'],
      photo:              json['photo'],
    );
  }
}
