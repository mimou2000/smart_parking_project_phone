import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'search_page.dart';
import 'bookings_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import '../backend/app_locale.dart';
import '../backend/guest_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SearchPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: guestModeNotifier,
          builder: (context, isGuest, _) {
            return Scaffold(
              body: Column(
                children: [
                  if (isGuest) _buildGuestBanner(context),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomNav(),
            );
          },
        );
      },
    );
  }

  // ══ شريط تحذير وضع الضيف ══
  Widget _buildGuestBanner(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3CD),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.userSecret, size: 13, color: Color(0xFF856404)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('guest_banner'),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF856404)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  GuestService.exitGuestMode();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) {
                      // إعادة تحميل LoginPage
                      // نستورد LoginPage هنا لتجنب circular import
                      // استخدم: import 'login_page.dart'; في أعلى الملف
                      return const _GoToLogin();
                    }),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF856404),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('guest_login_now'),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final bool isRtl = AppLocale.current.languageCode == 'ar';

    final List<Widget> navItems = [
      _navItem(index: 0, icon: FontAwesomeIcons.mapLocationDot, label: tr('nav_search')),
      _navItem(index: 1, icon: FontAwesomeIcons.rectangleList,   label: tr('nav_bookings')),
      _navItem(index: 2, icon: FontAwesomeIcons.circleUser,      label: tr('nav_profile')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: C.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            textDirection: Directionality.of(context),
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isRtl ? navItems.reversed.toList() : navItems,
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool sel = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(colors: [C.primary, C.secondary])
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          textDirection: Directionality.of(context),   // هام للأيقونة والنص داخل التبويب
          children: [
            Icon(icon, size: 16, color: sel ? C.white : C.muted),
            if (sel) ...[
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(
                      color: C.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

// ══ Widget مساعد: يُوجّه إلى LoginPage عند الضغط على "سجّل دخولك الآن" ══
class _GoToLogin extends StatelessWidget {
  const _GoToLogin();
  @override
  Widget build(BuildContext context) => const LoginPage();
}