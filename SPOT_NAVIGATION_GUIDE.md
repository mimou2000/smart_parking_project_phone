# 🚗 دليل توجيه الموقف (Spot Navigation)

## 📋 ملخص التغييرات

تمت إضافة خيار التوجيه المباشر للموقف (Spot) بالإضافة إلى توجيه المنطقة (Zone). الآن المستخدم يمكنه اختيار موقف معين والحصول على اتجاهات دقيقة مباشرة إلى ذلك الموقف.

---

## 🔧 التعديلات المجراة

### 1️⃣ **firebase_service.dart**
**ما تم تعديله:**
- ✅ تحديث نموذج `RealSpot` لإضافة إحداثيات الموقف:
  - `lat` (خط العرض)
  - `lng` (خط الطول)

- ✅ تحديث دالة `spotsStream()` لاستخراج الإحداثيات من Firestore:
  ```dart
  double lat = (d['lat'] ?? d['latitude']) as double? ?? 0.0;
  double lng = (d['lng'] ?? d['longitude']) as double? ?? 0.0;
  ```

**متطلبات Firestore:**
يجب أن تحتوي كل وثيقة موقف على:
```json
{
  "spot_number": "A1",
  "spot_type": "عادي",
  "status": "AVAILABLE",
  "lat": 36.7637,      // ← مهم
  "lng": 3.0588        // ← مهم
}
```

---

### 2️⃣ **navigation_page.dart**
**ما تم تعديله:**
- ✅ إضافة معاملات اختيارية للـ constructor:
  ```dart
  final double? destLat;        // إحداثيات المقصد (موقف أو منطقة)
  final double? destLng;
  final String? destinationName;  // اسم المقصد (موقف أو منطقة)
  ```

- ✅ تحديث دالة `_fetchRoute()`:
  ```dart
  final destLat = widget.destLat ?? widget.zone.lat;
  final destLng = widget.destLng ?? widget.zone.lng;
  ```

- ✅ تحديث رسائل الوصول والعناوين:
  ```dart
  final destName = widget.destinationName ?? widget.zone.name;
  _speak('لقد وصلت إلى وجهتك، $destName');
  ```

---

### 3️⃣ **booking_page.dart**
**ما تم تعديله:**
- ✅ إضافة **زر توجيه الموقف** يظهر عند اختيار موقف:
  - يعرض بلون مختلف (أزرق أساسي `C.primary`)
  - يظهر بجانب زر التوجيه العادي (أخضر `C.accent`)
  - يمرر إحداثيات الموقف المحددة إلى `NavigationPage`

```dart
NavigationPage(
  zone: widget.zone,
  destLat: _selectedSpot!.lat,
  destLng: _selectedSpot!.lng,
  destinationName: _selectedSpot!.spotName,
)
```

---

## 🎯 كيفية الاستخدام

### للمستخدم:
1. اختر منطقة وقوف (Zone)
2. اختر موقف معين (Spot) من القائمة
3. ستظهر زرتين للتوجيه:
   - 🔵 **زر أزرق "الموقف"** → توجيه مباشر للموقف المحدد
   - 🟢 **زر أخضر "الاتجاه"** → توجيه للمنطقة بأكملها

### للمطور:
#### استدعاء NavigationPage للموقف:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NavigationPage(
      zone: zone,
      destLat: spot.lat,
      destLng: spot.lng,
      destinationName: spot.spotName,
    ),
  ),
);
```

#### استدعاء NavigationPage للمنطقة (التقليدي):
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NavigationPage(zone: zone),
  ),
);
```

---

## ⚙️ متطلبات Firestore

**تأكد من وجود الحقول التالية لكل موقف:**

```json
{
  "docId": "spot_001",
  "spot_number": "A1",
  "spot_type": "عادي",
  "status": "AVAILABLE",
  "lat": 36.7637,    // ← جديد: خط العرض
  "lng": 3.0588      // ← جديد: خط الطول
}
```

---

## 🔄 الخطوات لتفعيل الميزة

1. **تحديث Firestore:**
   - أضف حقول `lat` و `lng` لكل موقف

2. **اختبار الميزة:**
   - أنشئ حجز في تطبيق الهاتف
   - اختر موقف
   - انقر على زر "الموقف"
   - تحقق من التوجيه المباشر للموقف

3. **استكشاف الأخطاء:**
   - إذا لم يظهر الزر الأزرق، تأكد من وجود موقف مختار (`_selectedSpot != null`)
   - إذا كان التوجيه غير دقيق، تحقق من قيم `lat` و `lng` في Firestore

---

## 📊 البنية الكاملة

```
BookingPage
├── MapSection (الخريطة مع الأزرار)
│   ├── زر التوجيه "الموقف" (جديد - أزرق)
│   └── زر التوجيه "الاتجاه" (أخضر)
├── DetailsSection
│   ├── InfoCard (معلومات المنطقة)
│   ├── SpotSelector (اختيار الموقف)
│   │   └── يعين قيمة _selectedSpot
│   └── BookingForm
└── NavigationPage (يقبل إحداثيات الموقف أو المنطقة)
```

---

## ✅ اختبار سريع

```dart
// قبل الميزة الجديدة:
NavigationPage(zone: zone)
↓
يوجه إلى: zone.lat, zone.lng

// بعد الميزة الجديدة:
NavigationPage(
  zone: zone,
  destLat: 36.7640,  // إحداثيات الموقف
  destLng: 3.0591,
  destinationName: "A1"
)
↓
يوجه إلى: 36.7640, 3.0591 (الموقف المحدد بدقة)
```

---

## 🚀 ملاحظات نهائية

- ✅ الميزة **اختيارية**: كل الكود السابق يعمل بدون تغييرات
- ✅ إذا لم يتم تمرير `destLat` و `destLng`، سيتم استخدام إحداثيات المنطقة تلقائياً
- ✅ الزر الأزرق "الموقف" يظهر فقط عند اختيار موقف معين
- ✅ لا تأثير على الأداء - الحسابات واحدة فقط

**شكراً لاستخدام النظام! 🎉**
