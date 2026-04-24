import 'package:flutter/material.dart';

class TripModel {
  final int     id;
  final String  clientName;
  final String  origin;
  final String  destination;
  final String  status;
  final String  scheduledStart;
  final String  cargoDescription;
  final String  cargoType;
  final int?    driverId;
  final int?    horseId;
  final int?    trailerId;
  final int?    startOdometer;
  final int?    endOdometer;
  final String? actualStart;
  final String? actualEnd;
  final double? distanceKm;

  TripModel({
    required this.id,
    required this.clientName,
    required this.origin,
    required this.destination,
    required this.status,
    required this.scheduledStart,
    required this.cargoDescription,
    required this.cargoType,
    this.driverId,
    this.horseId,
    this.trailerId,
    this.startOdometer,
    this.endOdometer,
    this.actualStart,
    this.actualEnd,
    this.distanceKm,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    id:               json['id'],
    clientName:       json['client_name']       ?? '',
    origin:           json['origin']            ?? '',
    destination:      json['destination']       ?? '',
    status:           json['status']            ?? 'scheduled',
    scheduledStart:   json['scheduled_start']   ?? '',
    cargoDescription: json['cargo_description'] ?? '',
    cargoType:        json['cargo_type']        ?? 'general',
    driverId:         json['driver'],
    horseId:          json['horse'],
    trailerId:        json['trailer'],
    startOdometer:    json['start_odometer'],
    endOdometer:      json['end_odometer'],
    actualStart:      json['actual_start'],
    actualEnd:        json['actual_end'],
    distanceKm:       (json['distance_km'] as num?)?.toDouble(),
  );

  Color get statusColor {
    switch (status) {
      case 'in_progress': return const Color(0xFF1DB8A0);
      case 'completed':   return const Color(0xFF38A169);
      case 'cancelled':   return const Color(0xFFE53E3E);
      default:            return const Color(0xFFDD6B20);
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
}
