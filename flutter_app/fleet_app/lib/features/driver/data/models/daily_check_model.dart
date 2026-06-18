import 'package:flutter/material.dart';

class DailyCheckModel {
  final String  id;
  final String  horseId;
  final String? trailerId;
  final String? tripId;
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

  // Handles both old bool values and new string values ('good'/'low'/'critical').
  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v == 'good' || v == 'true';
    return false;
  }

  // Derives tyrePressure from the 20-position map (current schema), the
  // legacy 4-tyre strings, or the original legacy bool — in that order.
  static bool _tyrePressure(Map<String, dynamic> j) {
    const bad = {'low_pressure', 'burst_risk'};
    final positions = j['tyre_positions'];
    if (positions is Map) return positions.values.every((v) => !bad.contains(v));
    if (j.containsKey('tyre_fl')) {
      return !bad.contains(j['tyre_fl']) && !bad.contains(j['tyre_fr']) &&
             !bad.contains(j['tyre_rl']) && !bad.contains(j['tyre_rr']);
    }
    return _b(j['tyre_pressure']);
  }

  // Derives tyreCondition from the 20-position map (current schema), the
  // legacy 4-tyre strings, or the original legacy bool — in that order.
  static bool _tyreCondition(Map<String, dynamic> j) {
    const bad = {'damaged', 'burst_risk'};
    final positions = j['tyre_positions'];
    if (positions is Map) return positions.values.every((v) => !bad.contains(v));
    if (j.containsKey('tyre_fl')) {
      return !bad.contains(j['tyre_fl']) && !bad.contains(j['tyre_fr']) &&
             !bad.contains(j['tyre_rl']) && !bad.contains(j['tyre_rr']);
    }
    return _b(j['tyre_condition']);
  }

  factory DailyCheckModel.fromJson(Map<String, dynamic> j) => DailyCheckModel(
    id:                  j['id']?.toString()         ?? '',
    horseId:             j['horse_id']?.toString()   ?? j['horse']?.toString() ?? '',
    trailerId:           j['trailer_id']?.toString() ?? j['trailer']?.toString(),
    tripId:              j['trip_id']?.toString()    ?? j['trip']?.toString(),
    overallStatus:       j['overall_status']         ?? 'pass',
    checkDate:           j['check_date']             ?? '',
    notes:               j['notes']?.toString(),
    odometer:            j['odometer'] is int
                           ? j['odometer'] as int
                           : int.tryParse(j['odometer']?.toString() ?? ''),
    oilLevel:            _b(j['oil_level']),
    coolantLevel:        _b(j['coolant_level']),
    noEngineLeaks:       _b(j['no_engine_leaks'] ?? j['no_leaks']),
    tyrePressure:        _tyrePressure(j),
    tyreCondition:       _tyreCondition(j),
    wheelNuts:           _b(j['wheel_nuts']),
    brakeResponse:       _b(j['brake_response']),
    airPressure:         _b(j['air_pressure']),
    headlights:          _b(j['headlights']),
    indicators:          _b(j['indicators']),
    brakeLights:         _b(j['brake_lights']),
    fireExtinguisher:    _b(j['fire_extinguisher']),
    reflectiveTriangles: _b(j['reflective_triangles']),
    seatbelt:            _b(j['seatbelt']),
    // new schema uses 'trailer_tyres' (bool), old used same key — compatible
    trailerTyres:        _b(j['trailer_tyres']),
    // new schema uses 'coupling_lock', old used 'coupling_system'
    couplingSystem:      _b(j['coupling_lock'] ?? j['coupling_system']),
    trailerLights:       _b(j['trailer_lights']),
    // new schema uses 'cargo_straps', old used 'cargo_locking'
    cargoLocking:        _b(j['cargo_straps'] ?? j['cargo_locking']),
    trailerSuspension:   _b(j['trailer_suspension']),
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
