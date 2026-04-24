import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ════════════════════════════════════════════
// دالة مساعدة: تحويل أي قيمة (String أو num) إلى double بأمان
// ════════════════════════════════════════════
double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

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
// نوع المركبة (VehicleType)
// ════════════════════════════════════════════
enum VehicleType {
  standard,      // سيارة عادية
  vip,           // سيارة فاخرة
  motorcycle,    // دراجة نارية
  electric,      // سيارة كهربائية
  disabled;      // ذوي الاحتياجات الخاصة

  String get label {
    switch (this) {
      case VehicleType.standard:   return 'سيارة عادية';
      case VehicleType.vip:        return 'سيارة فاخرة';
      case VehicleType.motorcycle: return 'دراجة نارية';
      case VehicleType.electric:   return 'سيارة كهربائية';
      case VehicleType.disabled:   return 'ذوي الاحتياجات الخاصة';
    }
  }

  String get spotType {
    switch (this) {
      case VehicleType.standard:   return 'STANDARD';
      case VehicleType.vip:        return 'VIP';
      case VehicleType.motorcycle: return 'MOTORCYCLE';
      case VehicleType.electric:   return 'ELECTRIC';
      case VehicleType.disabled:   return 'DISABLED';
    }
  }

  static VehicleType fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'VIP':        return VehicleType.vip;
      case 'MOTORCYCLE': return VehicleType.motorcycle;
      case 'ELECTRIC':   return VehicleType.electric;
      case 'DISABLED':   return VehicleType.disabled;
      default:           return VehicleType.standard;
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
  final double lat;
  final double lng;

  const RealSpot({
    required this.docId,
    required this.spotName,
    required this.spotType,
    required this.status,
    required this.lat,
    required this.lng,
  });

  bool get isAvailable => status == SpotStatus.available;
}

// ════════════════════════════════════════════
// 3. نموذج سجل الحجز (BookingRecord) — محدث ومتوافق مع كل الصفحات
// ════════════════════════════════════════════
class BookingRecord {
  final String id;
  final String zoneId;
  final String zoneName;
  final String address;
  final String spotId;
  final String spotName;
  final DateTime startTime;
  final int quantity;
  final double totalPrice;
  final String status;
  final String type;            // 'hourly', 'daily', 'weekly'
  // ── إحداثيات المنطقة والموقف ──
  final double zoneLat;
  final double zoneLng;
  final double spotLat;
  final double spotLng;
  // ── بيانات صاحب الحجز ──
  final String userName;

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
    this.zoneLat = 0,
    this.zoneLng = 0,
    this.spotLat = 0,
    this.spotLng = 0,
    this.userName = '',
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

  /// تدفق حالة تسجيل الدخول — يُستخدم للحفاظ على الجلسة عند إعادة فتح التطبيق
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ── دوال المصادقة ──
  // ملاحظة: على تطبيقات الجوال Firebase Auth يحافظ على الجلسة تلقائياً
  // بحيث يبقى المستخدم مسجّلاً حتى بعد إغلاق التطبيق.
  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// تغيير كلمة المرور — يتطلب إعادة مصادقة بالبريد وكلمة المرور الحالية
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('لم يتم تسجيل الدخول');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  static Future<void> register({
    required String email,
    required String password,
    required String name,
    required String carType,
    required String carModel,
    required String plate,
    required VehicleType vehicleType,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'carType': carType,
        'carModel': carModel,
        'plate': plate.toUpperCase(),
        'vehicleType': vehicleType.spotType,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> signOut() async => await _auth.signOut();

  /// إرسال رابط إعادة تعيين كلمة المرور
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── بيانات المستخدم ──
  static Stream<Map<String, dynamic>?> userProfileStream() {
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((s) => s.data());
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update(data);
  }

  // ── الحصول على نوع مركبة المستخدم ──
  static Future<VehicleType> getUserVehicleType() async {
    if (uid == null) return VehicleType.standard;
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return VehicleType.standard;
    return VehicleType.fromString(data['vehicleType'] as String?);
  }

  // ── Stream نوع مركبة المستخدم ──
  static Stream<VehicleType> userVehicleTypeStream() {
    if (uid == null) return Stream.value(VehicleType.standard);
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return VehicleType.standard;
      return VehicleType.fromString(data['vehicleType'] as String?);
    });
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

      // ✅ إصلاح: تحويل الإحداثيات بأمان سواء كانت String أو num
      final double lat = _toDouble(d['lat'] ?? d['latitude']);
      final double lng = _toDouble(d['lng'] ?? d['longitude']);

      // الحالة: نحوّلها للأحرف الكبيرة لضمان التوافق مع SpotStatus
      final rawStatus = (d['status'] as String? ?? 'AVAILABLE').toUpperCase();

      return RealSpot(
        docId: doc.id,
        spotName: d['spot_number'] ?? d['spotName'] ?? d['name'] ?? 'غير معروف',
        spotType: (d['spot_type'] ?? d['spotType'] ?? d['type'] ?? 'STANDARD').toString().toUpperCase(),
        status: SpotStatus.fromString(rawStatus),
        lat: lat,
        lng: lng,
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
    double zoneLat = 0,
    double zoneLng = 0,
    double spotLat = 0,
    double spotLng = 0,
  }) async {
    if (uid == null) throw Exception("يجب تسجيل الدخول أولاً");

    // ── جلب اسم المستخدم من ملف الحساب لتخزينه مع الحجز ──
    String userName = '';
    String userEmail = currentUser?.email ?? '';
    String userPlate = '';
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data();
      if (userData != null) {
        userName = (userData['name'] as String?)?.trim() ?? '';
        userPlate = (userData['plate'] as String?) ?? '';
      }
    } catch (_) {}
    if (userName.isEmpty) {
      userName = currentUser?.displayName ?? userEmail.split('@').first;
    }

    final batch = _db.batch();
    final bookingRef = _db.collection('reservations').doc();
    final spotRef = _db
        .collection('zones')
        .doc(zoneId)
        .collection('parking_spots')
        .doc(spotId);

    batch.set(bookingRef, {
      'user_id':        uid,
      'user_name':      userName,
      'user_email':     userEmail,
      'user_plate':     userPlate,
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
      'zone_lat':       zoneLat,
      'zone_lng':       zoneLng,
      'spot_lat':       spotLat,
      'spot_lng':       spotLng,
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
        totalPrice: _toDouble(d['total_price']),  // ✅ إصلاح
        status: d['status'] ?? 'active',
        type: d['rate_type'] ?? 'hourly',
        zoneLat: _toDouble(d['zone_lat']),  // ✅ إصلاح
        zoneLng: _toDouble(d['zone_lng']),  // ✅ إصلاح
        spotLat: _toDouble(d['spot_lat']),  // ✅ إصلاح
        spotLng: _toDouble(d['spot_lng']),  // ✅ إصلاح
        userName: (d['user_name'] as String?) ?? '',
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
