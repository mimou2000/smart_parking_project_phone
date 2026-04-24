import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/firebase_options.dart';
import '../backend/firebase_service.dart';
import 'login_page.dart';
import 'home_shell.dart';

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
      // ── بوابة المصادقة: تُبقي الجلسة محفوظة بعد إغلاق التطبيق ──
      home: const AuthGate(),
    );
  }
}

// ════════════════════════════════════════════
// AuthGate — يستمع لحالة تسجيل الدخول
// إذا كان المستخدم مسجلاً مسبقاً → HomeShell مباشرة
// وإلا → LoginPage
// ════════════════════════════════════════════
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.authStateChanges(),
      builder: (context, snapshot) {
        // أثناء التحقق من الجلسة المحفوظة → شاشة بدء بسيطة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final user = snapshot.data;
        if (user != null) {
          return const HomeShell();
        }
        return const LoginPage();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.panelDark1, C.panelDark2, C.panelDark3],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "SmartParking",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
      ),
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
