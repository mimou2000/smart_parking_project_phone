import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../backend/firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartParkingApp());
}

class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartParking',
      theme: ThemeData(
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(seedColor: C.primary),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ══ الألوان المشتركة في كامل التطبيق ══
class C {
  static const primary    = Color(0xFF6366F1);
  static const secondary  = Color(0xFFA855F7);
  static const accent     = Color(0xFF06B6D4);
  static const dark       = Color(0xFF1E293B);
  static const muted      = Color(0xFF64748B);
  static const border     = Color(0xFFE2E8F0);
  static const light      = Color(0xFFF8FAFC);
  static const white      = Color(0xFFFFFFFF);
  static const success    = Color(0xFF10B981);
  static const warning    = Color(0xFFF59E0B);
  static const error      = Color(0xFFEF4444);
  static const panelDark1 = Color(0xFF2D1B69);
  static const panelDark2 = Color(0xFF1A0A3E);
  static const panelDark3 = Color(0xFF3B1D8A);
}
