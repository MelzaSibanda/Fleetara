import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TripModel {
  final String  id;
  final String  clientName;
  final String  origin;
  final String  destination;
  final String  status;
  final String  scheduledStart;
  final String  cargoDescription;
  final String  cargoType;

  final String  driverName;
  final String  horseReg;
  final String  trailerReg;

  final String? driverId;
  final String? horseId;
  final String? trailerId;

  final int?    startOdometer;
  final int?    endOdometer;
  final String? actualStart;
  final String? actualEnd;
  final String? notes;

  TripModel({
    required this.id,
    required this.clientName,
    required this.origin,
    required this.destination,
    required this.status,
    required this.scheduledStart,
    required this.cargoDescription,
    required this.cargoType,
    this.driverName = '',
    this.horseReg   = '',
    this.trailerReg = '',
    this.driverId,
    this.horseId,
    this.trailerId,
    this.startOdometer,
    this.endOdometer,
    this.actualStart,
    this.actualEnd,
    this.notes,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id:               json['id']?.toString()             ?? '',
      clientName:       json['client_name']                ?? '',
      origin:           json['origin']                     ?? '',
      destination:      json['destination']                ?? '',
      status:           json['status']                     ?? 'scheduled',
      scheduledStart:   json['scheduled_start']            ?? '',
      cargoDescription: json['cargo_description']          ?? '',
      cargoType:        json['cargo_type']                 ?? 'general',
      driverName:       json['driver_name']                ?? '',
      horseReg:         json['horse_reg']                  ?? '',
      trailerReg:       json['trailer_reg']                ?? '',
      driverId:         json['driver_id']?.toString(),
      horseId:          json['horse_id']?.toString(),
      trailerId:        json['trailer_id']?.toString(),
      startOdometer:    json['start_odometer'] is int ? json['start_odometer'] : null,
      endOdometer:      json['end_odometer']   is int ? json['end_odometer']   : null,
      actualStart:      json['actual_start'],
      actualEnd:        json['actual_end'],
      notes:            json['notes'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'in_progress': return AppTheme.primary;
      case 'completed':   return AppTheme.emerald;
      case 'cancelled':   return AppTheme.rose;
      default:            return AppTheme.amber;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'in_progress': return 'In Progress';
      case 'completed':   return 'Completed';
      case 'cancelled':   return 'Cancelled';
      default:            return 'Scheduled';
    }
  }

  String get formattedDate {
    if (scheduledStart.length >= 10) return scheduledStart.substring(0, 10);
    return scheduledStart;
  }
}
