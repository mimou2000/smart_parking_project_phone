# SmartParking — دليل الإعداد

## هيكل الملفات

```
lib/
├── main.dart              ← نقطة البداية + Firebase init + ألوان C
├── firebase_options.dart  ← إعدادات Firebase لكل منصة
├── firebase_service.dart  ← طبقة خدمات Firebase (Auth + Firestore)
├── login_page.dart        ← تسجيل الدخول (Firebase Auth)
├── register_page.dart     ← إنشاء حساب (Firebase Auth + Firestore)
├── home_shell.dart        ← Bottom Navigation
├── search_page.dart       ← البحث (Stream من parkingZones)
├── booking_page.dart      ← الحجز (Transaction Firestore)
├── bookings_page.dart     ← حجوزاتي (Stream من bookings)
└── profile_page.dart      ← الحساب الشخصي (Stream من users)
```

---

## خطوات الإعداد

### 1. تثبيت المتطلبات

```bash
flutter pub get
```

### 2. ربط Firebase

```bash
# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# ربط المشروع (سيولّد firebase_options.dart تلقائياً)
flutterfire configure --project=smartparking-realtime
```

### 3. Android — أضف google-services.json

- نزّل `google-services.json` من Firebase Console
- ضعه في `android/app/google-services.json`
- تأكد من وجود هذا في `android/app/build.gradle`:
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  ```

### 4. iOS — أضف GoogleService-Info.plist

- نزّل `GoogleService-Info.plist` من Firebase Console
- اسحبه إلى Xcode داخل `Runner/`

### 5. بذر بيانات Firestore الأولية

```bash
cd smartparking
npm install firebase
node seed_firestore.js
```

سيُنشئ هذا:
- 4 مناطق وقوف في `parkingZones/`
- مواقف صغيرة في `parkingZones/{id}/spots/`

### 6. نشر قواعد Firestore

```bash
firebase deploy --only firestore:rules
```

### 7. تشغيل التطبيق

```bash
flutter run
```

---

## هيكل Firestore

```
parkingZones/
  {zoneId}/
    name, address, lat, lng,
    totalSpots, availableSpots,
    pricePerHour, distance
    spots/
      {spotId}/
        number, isTaken

bookings/
  {bookingId}/
    userId, zoneId, zoneName, address,
    spotNumber, hours, totalPrice,
    status (active|completed|cancelled),
    createdAt

users/
  {uid}/
    name, email, plate, carType, createdAt
```

---

## المميزات المضافة مع Firebase

| الميزة | التفاصيل |
|--------|----------|
| 🔐 Auth حقيقي | تسجيل دخول/خروج/إنشاء حساب بـ FirebaseAuth |
| 🔴 Real-time | مناطق الوقوف تتحدث فورياً عبر Stream |
| 🔒 Transaction | الحجز يستخدم Firestore Transaction لمنع التعارض |
| 📋 حجوزاتي | Stream حقيقي من Firestore مرتّب بالتاريخ |
| 👤 ملف شخصي | بيانات حقيقية من Firestore مع إمكانية التعديل |
| ❌ إلغاء الحجز | يُحرّر الموقف فورياً عبر Transaction |
| 🛡️ Security Rules | قواعد أمان Firestore شاملة |
| ⚠️ رسائل خطأ | رسائل خطأ عربية واضحة لكل حالة |
