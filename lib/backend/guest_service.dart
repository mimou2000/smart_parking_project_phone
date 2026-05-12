// ════════════════════════════════════════════════════════════════════════════
//  guest_service.dart — خدمة وضع الضيف مع بيانات تجريبية
//
//  الاستخدام:
//    GuestService.enterGuestMode();   // عند الضغط على "دخول كضيف"
//    GuestService.isGuest            // true/false
//    GuestService.guestZones         // قائمة المناطق التجريبية
//    GuestService.guestBookings      // قائمة الحجوزات التجريبية
//    GuestService.exitGuestMode();   // عند تسجيل الدخول / الخروج
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../frontend/parking_zone.dart';
import '../backend/firebase_service.dart';

// ══ Notifier عام يُخطر كل الواجهات بتغيّر حالة الضيف ══
final ValueNotifier<bool> guestModeNotifier = ValueNotifier<bool>(false);

class GuestService {
  GuestService._();

  // ── الحالة ──────────────────────────────────────────────────────────────
  static bool get isGuest => guestModeNotifier.value;

  static void enterGuestMode() => guestModeNotifier.value = true;
  static void exitGuestMode()  => guestModeNotifier.value = false;

  // ════════════════════════════════════════════════════════════════════════
  //  بيانات المناطق التجريبية (Demo Zones)
  //  مبنية على مناطق واقعية في سطيف — الجزائر
  // ════════════════════════════════════════════════════════════════════════
  static List<ParkingZone> get guestZones => [
    ParkingZone(
      id:             'demo_zone_1',
      name:           'موقف ساحة الأمير عبد القادر',
      address:        'شارع الأمير عبد القادر، وسط مدينة سطيف',
      lat:            36.1898,
      lng:            5.4100,
      totalSpots:     40,
      availableSpots: 12,
      pricePerHour:   50,
      pricePerDay:    400,
      pricePerWeek:   2380,
      distance:       0.3,
      spotTypes: {
        'STANDARD':   20,
        'VIP':        8,
        'MOTORCYCLE': 7,
        'DISABLED':   5,
      },
    ),
    ParkingZone(
      id:             'demo_zone_2',
      name:           'موقف السوق الكبير',
      address:        'السوق المركزي، سطيف',
      lat:            36.1870,
      lng:            5.4068,
      totalSpots:     60,
      availableSpots: 0,
      pricePerHour:   40,
      pricePerDay:    300,
      pricePerWeek:   1785,
      distance:       0.7,
      spotTypes: {
        'STANDARD':   35,
        'VIP':        10,
        'MOTORCYCLE': 10,
        'ELECTRIC':   5,
      },
    ),
    ParkingZone(
      id:             'demo_zone_3',
      name:           'موقف المستشفى الجامعي',
      address:        'المستشفى الجامعي سعيدان، سطيف',
      lat:            36.1930,
      lng:            5.3985,
      totalSpots:     80,
      availableSpots: 35,
      pricePerHour:   30,
      pricePerDay:    200,
      pricePerWeek:   1190,
      distance:       1.2,
      spotTypes: {
        'STANDARD':   40,
        'DISABLED':   20,
        'MOTORCYCLE': 15,
        'ELECTRIC':   5,
      },
    ),
    ParkingZone(
      id:             'demo_zone_4',
      name:           'موقف محطة القطار',
      address:        'محطة سكة حديد سطيف',
      lat:            36.1855,
      lng:            5.4210,
      totalSpots:     50,
      availableSpots: 28,
      pricePerHour:   35,
      pricePerDay:    250,
      pricePerWeek:   1487,
      distance:       1.8,
      spotTypes: {
        'STANDARD':   30,
        'VIP':        5,
        'MOTORCYCLE': 10,
        'ELECTRIC':   5,
      },
    ),
    ParkingZone(
      id:             'demo_zone_5',
      name:           'موقف مركز التسوق',
      address:        'شارع 8 ماي 1945، سطيف',
      lat:            36.1910,
      lng:            5.4155,
      totalSpots:     100,
      availableSpots: 67,
      pricePerHour:   60,
      pricePerDay:    500,
      pricePerWeek:   2975,
      distance:       2.1,
      spotTypes: {
        'STANDARD':   50,
        'VIP':        20,
        'ELECTRIC':   15,
        'MOTORCYCLE': 10,
        'DISABLED':   5,
      },
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════
  //  بيانات الحجوزات التجريبية (Demo Bookings)
  // ════════════════════════════════════════════════════════════════════════
  static List<BookingRecord> get guestBookings => [
    BookingRecord(
      id:         'demo_booking_1',
      zoneId:     'demo_zone_1',
      zoneName:   'موقف ساحة الأمير عبد القادر',
      address:    'شارع الأمير عبد القادر، وسط مدينة سطيف',
      spotId:     'demo_spot_A1',
      spotName:   'A-1',
      startTime:  DateTime.now().subtract(const Duration(hours: 1)),
      quantity:   3,
      totalPrice: 150,
      status:     'active',
      type:       'hourly',
      zoneLat:    36.1898,
      zoneLng:    5.4100,
      spotLat:    36.1899,
      spotLng:    5.4101,
      userName:   'زائر',
    ),
    BookingRecord(
      id:         'demo_booking_2',
      zoneId:     'demo_zone_3',
      zoneName:   'موقف المستشفى الجامعي',
      address:    'المستشفى الجامعي سعيدان، سطيف',
      spotId:     'demo_spot_B5',
      spotName:   'B-5',
      startTime:  DateTime.now().subtract(const Duration(days: 3)),
      quantity:   1,
      totalPrice: 200,
      status:     'completed',
      type:       'daily',
      zoneLat:    36.1930,
      zoneLng:    5.3985,
      spotLat:    36.1931,
      spotLng:    5.3986,
      userName:   'زائر',
    ),
    BookingRecord(
      id:         'demo_booking_3',
      zoneId:     'demo_zone_4',
      zoneName:   'موقف محطة القطار',
      address:    'محطة سكة حديد سطيف',
      spotId:     'demo_spot_C3',
      spotName:   'C-3',
      startTime:  DateTime.now().subtract(const Duration(days: 7)),
      quantity:   2,
      totalPrice: 70,
      status:     'cancelled',
      type:       'hourly',
      zoneLat:    36.1855,
      zoneLng:    5.4210,
      spotLat:    36.1856,
      spotLng:    5.4211,
      userName:   'زائر',
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════
  //  بيانات الملف الشخصي التجريبي (Demo Profile)
  // ════════════════════════════════════════════════════════════════════════
  static Map<String, dynamic> get guestProfile => {
    'name':        'زائر تجريبي',
    'email':       'guest@smartparking.dz',
    'carType':     'Toyota',
    'carModel':    'Corolla',
    'plate':       '123 ABC 19',
    'vehicleType': 'STANDARD',
  };
}
