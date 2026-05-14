import 'package:flutter/material.dart';

class DailyCheckModel {
  final int     id;
  final int     horseId;
  final int?    trailerId;
  final int?    tripId;
  final String  overallStatus;
  final String  checkDate;
  final String? notes;
  final int?    odometer;

  // Horse — engine
  final bool oilLevel;
  final bool coolantLevel;
  final bool noEngineLeaks;
  // Horse — wheels
  final bool tyrePressure;
  final bool tyreCondition;
  final bool wheelNuts;
  // Horse — brakes
  final bool brakeResponse;
  final bool airPressure;
  // Horse — lights
  final bool headlights;
  final bool indicators;
  final bool brakeLights;
  // Horse — safety
  final bool fireExtinguisher;
  final bool reflectiveTriangles;
  final bool seatbelt;
  // Trailer
  final bool trailerTyres;
  final bool couplingSystem;
  final bool trailerLights;
  final bool cargoLocking;
  final bool trailerSuspension;

  const DailyCheckModel({
    required this.id,
    required this.horseId,
    this.trailerId,
    this.tripId,
    required this.overallStatus,
    required this.checkDate,
    this.notes,
    this.odometer,
    this.oilLevel = false,
    this.coolantLevel = false,
    this.noEngineLeaks = false,
    this.tyrePressure = false,
    this.tyreCondition = false,
    this.wheelNuts = false,
    this.brakeResponse = false,
    this.airPressure = false,
    this.headlights = false,
    this.indicators = false,
    this.brakeLights = false,
    this.fireExtinguisher = false,
    this.reflectiveTriangles = false,
    this.seatbelt = false,
    this.trailerTyres = false,
    this.couplingSystem = false,
    this.trailerLights = false,
    this.cargoLocking = false,
    this.trailerSuspension = false,
  });

  factory DailyCheckModel.fromJson(Map<String, dynamic> j) => DailyCheckModel(
    id:                  j['id'],
    horseId:             j['horse'],
    trailerId:           j['trailer'],
    tripId:              j['trip'],
    overallStatus:       j['overall_status'] ?? 'pass',
    checkDate:           j['check_date'] ?? '',
    notes:               j['notes'],
    odometer:            j['odometer'],
    oilLevel:            j['oil_level']            ?? false,
    coolantLevel:        j['coolant_level']         ?? false,
    noEngineLeaks:       j['no_engine_leaks']       ?? false,
    tyrePressure:        j['tyre_pressure']         ?? false,
    tyreCondition:       j['tyre_condition']        ?? false,
    wheelNuts:           j['wheel_nuts']            ?? false,
    brakeResponse:       j['brake_response']        ?? false,
    airPressure:         j['air_pressure']          ?? false,
    headlights:          j['headlights']            ?? false,
    indicators:          j['indicators']            ?? false,
    brakeLights:         j['brake_lights']          ?? false,
    fireExtinguisher:    j['fire_extinguisher']     ?? false,
    reflectiveTriangles: j['reflective_triangles']  ?? false,
    seatbelt:            j['seatbelt']              ?? false,
    trailerTyres:        j['trailer_tyres']         ?? false,
    couplingSystem:      j['coupling_system']       ?? false,
    trailerLights:       j['trailer_lights']        ?? false,
    cargoLocking:        j['cargo_locking']         ?? false,
    trailerSuspension:   j['trailer_suspension']    ?? false,
  );

  Color get statusColor {
    switch (overallStatus) {
      case 'pass':        return const Color(0xFF10B981);
      case 'minor_issue': return const Color(0xFFF59E0B);
      case 'critical':    return const Color(0xFFEF4444);
      default:            return const Color(0xFF6B7280);
    }
  }

  String get statusLabel {
    switch (overallStatus) {
      case 'pass':        return 'Pass';
      case 'minor_issue': return 'Minor Issue';
      case 'critical':    return 'Critical';
      default:            return overallStatus;
    }
  }
}
