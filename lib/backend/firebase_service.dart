import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ════════════════════════════════════════════
// 1. تعريف نوع الحجز (Enum)
// ════════════════════════════════════════════
enum BookingType {
  hourly,
  daily,
  weekly;

  String get label {
    switch (this) {
      case BookingType.hourly: return 'ساعي';
      case BookingType.daily:  return 'يومي';
      case BookingType.weekly: return 'أسبوعي';
    }
  }

  String get unit {
    switch (this) {
      case BookingType.hourly: return 'ساعة';
      case BookingType.daily:  return 'يوم';
      case BookingType.weekly: return 'أسبوع';
    }
  }

  int get maxQuantity {
    switch (this) {
      case BookingType.hourly: return 24;
      case BookingType.daily:  return 30;
      case BookingType.weekly: return 12;
    }
  }
}

// ════════════════════════════════════════════
// 2. نموذج بيانات الموقف (RealSpot)
// ════════════════════════════════════════════
// ════════════════════════════════════════════
// حالات الموقف (SpotStatus)
// ════════════════════════════════════════════
enum SpotStatus {
  available,
  occupied,
  reserved,
  maintenance;

  static SpotStatus fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'OCCUPIED':    return SpotStatus.occupied;
      case 'RESERVED':    return SpotStatus.reserved;
      case 'MAINTENANCE': return SpotStatus.maintenance;
      default:            return SpotStatus.available;
    }
  }

  String get toFirestore => name.toUpperCase();
}

class RealSpot {
  final String docId;
  final String spotName;
  final String spotType;
  final SpotStatus status;

  const RealSpot({
    required this.docId,
    required this.spotName,
    required this.spotType,
    required this.status,
  });

  bool get isAvailable => status == SpotStatus.available;
}

// ════════════════════════════════════════════
// 3. نموذج سجل الحجز (BookingRecord) — محدث ومتوافق مع كل الصفحات
// ════════════════════════════════════════════
class BookingRecord {
  final String id;
  final String zoneId;
  final String zoneName;        // ← تمت إضافته
  final String address;         // ← تمت إضافته
  final String spotId;
  final String spotName;
  final DateTime startTime;
  final int quantity;
  final double totalPrice;
  final String status;
  final String type;            // 'hourly', 'daily', 'weekly'

  BookingRecord({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.address,
    required this.spotId,
    required this.spotName,
    required this.startTime,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.type,
  });

  // دوال مساعدة للعرض في BookingsPage
  String get durationLabel {
    final unit = BookingType.values.byName(type).unit;
    return '$quantity $unit';
  }

  String get dateLabel {
    return "${startTime.day}/${startTime.month}/${startTime.year}";
  }

  int get hours {
    if (type == 'hourly') return quantity;
    if (type == 'daily') return quantity * 24;
    if (type == 'weekly') return quantity * 24 * 7;
    return quantity;
  }
}

// ════════════════════════════════════════════
// 4. خدمة Firebase المركزية — النسخة المصححة
// ════════════════════════════════════════════
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get uid => _auth.currentUser?.uid;
  static User? get currentUser => _auth.currentUser;

  // ── دوال المصادقة ──
  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> register({
    required String email,
    required String password,
    required String name,
    required String carType,
    required String plate,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'carType': carType,
        'plate': plate.toUpperCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> signOut() async => await _auth.signOut();

  // ── بيانات المستخدم ──
  static Stream<Map<String, dynamic>?> userProfileStream() {
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((s) => s.data());
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update(data);
  }

  // ── Stream المواقف (مستخدم في BookingPage) ──
  static Stream<List<RealSpot>> spotsStream(String zoneId) {
    return _db
        .collection('zones')
        .doc(zoneId)
        .collection('parking_spots')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final d = doc.data();
      return RealSpot(
        docId: doc.id,
        spotName: d['spot_number'] ?? d['spotName'] ?? d['name'] ?? 'غير معروف',
        spotType: d['spot_type'] ?? d['spotType'] ?? d['type'] ?? 'عادي',
        status: SpotStatus.fromString(d['status'] as String?),
      );
    }).toList());
  }

  // ── إنشاء حجز (تم تعديله ليتوافق مع BookingPage) ──
  static Future<void> createBooking({
    required String zoneId,
    required String zoneName,
    required String address,
    required String spotId,
    required String spotName,
    required String spotType,
    required BookingType bookingType,
    required int quantity,
    required double totalPrice,
  }) async {
    if (uid == null) throw Exception("يجب تسجيل الدخول أولاً");

    final batch = _db.batch();
    final bookingRef = _db.collection('reservations').doc();
    final spotRef = _db
        .collection('zones')
        .doc(zoneId)
        .collection('parking_spots')
        .doc(spotId);

    batch.set(bookingRef, {
      'user_id':        uid,
      'zone_id':        zoneId,
      'zone_name':      zoneName,
      'address':        address,
      'spot_id':        spotId,
      'spot_number':    spotName,
      'spot_type':      spotType,
      'rate_type':      bookingType.name,
      'duration':       quantity,
      'total_price':    totalPrice,
      'total_cost':     totalPrice,
      'status':         'active',
      'source':         'APP',
      'reservation_id': bookingRef.id,
      'start_time':     FieldValue.serverTimestamp(),
      'created_at':     FieldValue.serverTimestamp(),
    });

    batch.update(spotRef, {
      'status':     SpotStatus.occupied.toFirestore, // 'OCCUPIED'
      'booked_by':  uid,
      'booking_id': bookingRef.id,
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── حجوزاتي ──
  static Stream<List<BookingRecord>> myBookingsStream() {
    if (uid == null) return Stream.value([]);

    return _db.collection('reservations')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final d = doc.data();
      return BookingRecord(
        id: doc.id,
        zoneId: d['zone_id'] ?? '',
        zoneName: d['zone_name'] ?? 'منطقة غير معروفة',
        address: d['address'] ?? '',
        spotId: d['spot_id'] ?? '',
        spotName: d['spot_number'] ?? 'موقف',
        startTime: (d['start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
        quantity: (d['duration'] ?? 0) as int,
        totalPrice: (d['total_price'] ?? 0).toDouble(),
        status: d['status'] ?? 'active',
        type: d['rate_type'] ?? 'hourly',
      );
    }).toList());
  }

  // ── إلغاء حجز ──
  static Future<void> cancelBooking(BookingRecord b) async {
    final batch = _db.batch();
    final bookingRef = _db.collection('reservations').doc(b.id);
    final spotRef = _db
        .collection('zones')
        .doc(b.zoneId)
        .collection('parking_spots')
        .doc(b.spotId);

    batch.update(bookingRef, {
      'status': 'cancelled',
      'cancelled_at': FieldValue.serverTimestamp(),
    });

    batch.update(spotRef, {
      'status':     SpotStatus.available.toFirestore, // 'AVAILABLE'
      'booked_by':  FieldValue.delete(),
      'booking_id': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── التقييمات ──
  static Stream<QuerySnapshot> getAllFeedback() {
    return _db.collection('feedback')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}