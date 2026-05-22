import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TripModel {
  final int     id;
  final String  clientName;
  final String  origin;
  final String  destination;
  final String  status;
  final String  scheduledStart;
  final String  cargoDescription;
  final String  cargoType;

  // Nested names (from TripDetailSerializer)
  final String driverName;
  final String horseReg;
  final String trailerReg;

  // Raw IDs (for edit form)
  final int? driverId;
  final int? horseId;
  final int? trailerId;

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
    // driver may be a nested object or an int ID
    final driverRaw = json['driver'];
    final horseRaw  = json['horse'];
    final trailerRaw= json['trailer'];

    String driverName = '';
    String horseReg   = '';
    String trailerReg = '';
    int? driverId, horseId, trailerId;

    if (driverRaw is Map) {
      driverId   = driverRaw['id'];
      driverName = ('${driverRaw['first_name'] ?? ''} ${driverRaw['last_name'] ?? ''}').trim();
      if (driverName.isEmpty) driverName = driverRaw['username'] ?? '';
    } else if (driverRaw is int) {
      driverId = driverRaw;
    }

    if (horseRaw is Map) {
      horseId = horseRaw['id'];
      horseReg = horseRaw['registration_number'] ?? '';
    } else if (horseRaw is int) {
      horseId = horseRaw;
    }

    if (trailerRaw is Map) {
      trailerId  = trailerRaw['id'];
      trailerReg = trailerRaw['registration_number'] ?? '';
    } else if (trailerRaw is int) {
      trailerId = trailerRaw;
    }

    return TripModel(
      id:               json['id'],
      clientName:       json['client_name']       ?? '',
      origin:           json['origin']            ?? '',
      destination:      json['destination']       ?? '',
      status:           json['status']            ?? 'scheduled',
      scheduledStart:   json['scheduled_start']   ?? '',
      cargoDescription: json['cargo_description'] ?? '',
      cargoType:        json['cargo_type']        ?? 'general',
      driverName:       driverName,
      horseReg:         horseReg,
      trailerReg:       trailerReg,
      driverId:         driverId,
      horseId:          horseId,
      trailerId:        trailerId,
      startOdometer:    json['start_odometer'],
      endOdometer:      json['end_odometer'],
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
