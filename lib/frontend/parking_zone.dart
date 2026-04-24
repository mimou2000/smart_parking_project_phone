import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  نموذج بيانات منطقة الوقوف
// ═══════════════════════════════════════════════════════════════════════════
class ParkingZone {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final int totalSpots;
  final int availableSpots;
  final double pricePerHour;
  final double pricePerDay;
  final double pricePerWeek;
  final double distance;
  final Map<String, int> spotTypes;

  const ParkingZone({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.totalSpots,
    required this.availableSpots,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.pricePerWeek,
    required this.distance,
    required this.spotTypes,
  });

  bool get isAvailable => availableSpots > 0;

  /// تحذير: هذا الـ factory يُعيّن availableSpots = totalSpots دائماً.
  /// استخدم [fromFirestoreWithAvailable] بدلاً منه للحصول على العدد الحقيقي.
  @Deprecated('استخدم fromFirestoreWithAvailable لحساب المواقف المتاحة بدقة')
  factory ParkingZone.fromFirestore(DocumentSnapshot doc,
      {double? userLat, double? userLng}) {
    final data = doc.data() as Map<String, dynamic>;

    final lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
    final lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;

    final spotTypesData = data['spot_types'] as Map<String, dynamic>? ?? {};
    final Map<String, int> spotTypes = {};
    int totalSpots = 0;
    spotTypesData.forEach((key, value) {
      int count = 0;
      if (value is num) {
        count = value.toInt();
      } else if (value is String) {
        count = int.tryParse(value) ?? 0;
      }
      spotTypes[key] = count;
      totalSpots += count;
    });

    int availableSpots = totalSpots;

    double pricePerHour = 0.0;
    double pricePerDay = 0.0;
    double pricePerWeek = 0.0;
    if (data['hourly_rate'] != null) {
      pricePerHour = (data['hourly_rate'] as num).toDouble();
    }
    if (data['daily_rate'] != null) {
      pricePerDay = (data['daily_rate'] as num).toDouble();
      if (pricePerHour == 0.0) pricePerHour = pricePerDay / 24;
    }
    if (data['weekly_rate'] != null) {
      pricePerWeek = (data['weekly_rate'] as num).toDouble();
    } else {
      pricePerWeek = pricePerDay > 0
          ? pricePerDay * 7 * 0.85
          : pricePerHour * 168 * 0.85;
    }
    if (pricePerDay == 0.0) pricePerDay = pricePerHour * 24;

    double distance = 0.0;
    if (userLat != null && userLng != null) {
      distance = haversineKm(userLat, userLng, lat, lng);
    } else {
      distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
    }

    return ParkingZone(
      id: doc.id,
      name: data['zone_name'] ?? data['name'] ?? 'موقف بدون اسم',
      address: data['location'] ?? data['address'] ?? '',
      lat: lat,
      lng: lng,
      totalSpots: totalSpots,
      availableSpots: availableSpots,
      pricePerHour: pricePerHour,
      pricePerDay: pricePerDay,
      pricePerWeek: pricePerWeek,
      distance: double.parse(distance.toStringAsFixed(1)),
      spotTypes: spotTypes,
    );
  }

  // ✅ Factory يحسب availableSpots الحقيقية من subcollection spots
  factory ParkingZone.fromFirestoreWithAvailable(
    DocumentSnapshot doc, {
    required int availableSpots,
    double? userLat,
    double? userLng,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
    final lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;

    final spotTypesData = data['spot_types'] as Map<String, dynamic>? ?? {};
    final Map<String, int> spotTypes = {};
    int totalSpots = 0;
    spotTypesData.forEach((key, value) {
      int count = 0;
      if (value is num) count = value.toInt();
      else if (value is String) count = int.tryParse(value) ?? 0;
      spotTypes[key] = count;
      totalSpots += count;
    });

    double pricePerHour = 0.0;
    double pricePerDay = 0.0;
    double pricePerWeek = 0.0;
    if (data['hourly_rate'] != null) {
      pricePerHour = (data['hourly_rate'] as num).toDouble();
    }
    if (data['daily_rate'] != null) {
      pricePerDay = (data['daily_rate'] as num).toDouble();
      if (pricePerHour == 0.0) pricePerHour = pricePerDay / 24;
    }
    if (data['weekly_rate'] != null) {
      pricePerWeek = (data['weekly_rate'] as num).toDouble();
    } else {
      pricePerWeek = pricePerDay > 0
          ? pricePerDay * 7 * 0.85
          : pricePerHour * 168 * 0.85;
    }
    if (pricePerDay == 0.0) pricePerDay = pricePerHour * 24;

    double distance = 0.0;
    if (userLat != null && userLng != null) {
      distance = haversineKm(userLat, userLng, lat, lng);
    }

    return ParkingZone(
      id: doc.id,
      name: data['zone_name'] ?? data['name'] ?? 'موقف',
      address: data['location'] ?? data['address'] ?? '',
      lat: lat,
      lng: lng,
      totalSpots: totalSpots,
      availableSpots: availableSpots,
      pricePerHour: pricePerHour,
      pricePerDay: pricePerDay,
      pricePerWeek: pricePerWeek,
      distance: double.parse(distance.toStringAsFixed(1)),
      spotTypes: spotTypes,
    );
  }
}

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}
