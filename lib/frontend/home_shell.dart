import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'search_page.dart';
import 'bookings_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

// ════════════════════════════════════════════
//  HomeShell — 4 تبويبات (البحث | حجوزاتي | تقييم | حسابي)
// ════════════════════════════════════════════
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
    FeedbackPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(index: 0, icon: FontAwesomeIcons.mapLocationDot, label: "البحث"),
              _navItem(index: 1, icon: FontAwesomeIcons.rectangleList,   label: "حجوزاتي"),
              _navItem(index: 2, icon: FontAwesomeIcons.commentDots,     label: "تقييم"),
              _navItem(index: 3, icon: FontAwesomeIcons.circleUser,      label: "حسابي"),
            ],
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
        child: Row(children: [
          Icon(icon, size: 16, color: sel ? C.white : C.muted),
          if (sel) ...[
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: C.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}
