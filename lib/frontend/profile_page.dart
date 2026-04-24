import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'login_page.dart';
import '../backend/firebase_service.dart';
import 'bookings_page.dart';
import 'feedback_page.dart';

// ════════════════════════════════════════════
//  صفحة الحساب الشخصي — Firestore
// ════════════════════════════════════════════
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.light,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: FirebaseService.userProfileStream(),
        builder: (context, profileSnap) {
final profile = profileSnap.data;
          final name  = profile?['name']    as String? ?? 'المستخدم';
          final email = profile?['email']   as String? ?? FirebaseService.currentUser?.email ?? '';
          final plate = profile?['plate']   as String? ?? '—';
          final car   = profile?['carType'] as String? ?? '—';
          final vehicleType = VehicleType.fromString(profile?['vehicleType'] as String?);

          return StreamBuilder<List<BookingRecord>>(
            stream: FirebaseService.myBookingsStream(),
            builder: (context, bookSnap) {
              final bookings   = bookSnap.data ?? [];
              final totalPaid  = bookings.fold<double>(0, (s, b) => s + (b.status != 'cancelled' ? b.totalPrice : 0));
              final totalHours = bookings.fold<int>(0,    (s, b) => s + (b.status != 'cancelled' ? b.hours : 0));

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, name, email),
_buildCarCard(plate, car, vehicleType),
                    _buildStatRow(bookings.length, totalPaid, totalHours),
                    _buildMenuSection(context, name, email, plate, car, vehicleType),
                    const SizedBox(height: 24),
                    _buildLogoutBtn(context),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.panelDark1, C.panelDark2, C.panelDark3],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(FontAwesomeIcons.gear, color: Colors.white, size: 14),
                  ),
                  const Text("حسابي",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 20),
              // الصورة
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [C.primary, C.secondary]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FontAwesomeIcons.circleCheck, color: Color(0xFF34D399), size: 12),
                    SizedBox(width: 6),
                    Text("حساب موثّق", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildCarCard(String plate, String carType, VehicleType vehicleType) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF1A2744)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(_vehicleTypeIcon(vehicleType), color: Colors.white38, size: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("مركبتي", style: TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 4),
              Text(plate.isNotEmpty ? plate : '—',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _vehicleTypeColor(vehicleType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vehicleType.label,
                            style: TextStyle(
                                color: _vehicleTypeColor(vehicleType),
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Icon(_vehicleTypeIcon(vehicleType),
                            size: 10, color: _vehicleTypeColor(vehicleType)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: C.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(carType, style: const TextStyle(color: C.accent, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(int count, double paid, int hours) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("$count", "حجوزات", FontAwesomeIcons.rectangleList, C.primary),
          _divider(),
          _stat("${paid.toInt()} دج", "مدفوع", FontAwesomeIcons.moneyBill, C.warning),
          _divider(),
          _stat("$hours س", "إجمالي", FontAwesomeIcons.clock, C.accent),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: C.border);

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: C.muted)),
    ]);
  }

Widget _buildMenuSection(BuildContext ctx, String name, String email, String plate, String carType, VehicleType vehicleType) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: C.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _menuItem(FontAwesomeIcons.userPen, "تعديل الملف الشخصي", C.primary, () => _editProfileDialog(ctx, name, email)),
        _menuDivider(),
        _menuItem(FontAwesomeIcons.car, "تعديل بيانات المركبة", C.accent, () => _editCarDialog(ctx, plate, carType, vehicleType)),
        _menuDivider(),
        _menuItem(FontAwesomeIcons.star,         "التقييمات",           C.warning,  () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const FeedbackPage()))),
        _menuDivider(),
        _menuItem(FontAwesomeIcons.bell,         "الإشعارات",           const Color(0xFFF97316),  () {}),
        _menuDivider(),
        _menuItem(FontAwesomeIcons.shieldHalved, "الأمان وكلمة المرور", C.secondary, () {}),
        _menuDivider(),
        _menuItem(FontAwesomeIcons.circleQuestion, "المساعدة والدعم",   C.muted,    () {}),
      ]),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(FontAwesomeIcons.angleLeft, size: 12, color: C.muted),
            Row(children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
              const SizedBox(width: 12),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 14, color: color),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Future<void> _editProfileDialog(BuildContext ctx, String name, String email) async {
    final nameCtrl = TextEditingController(text: name);
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل الملف الشخصي', textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        content: TextField(
          controller: nameCtrl, textAlign: TextAlign.right,
          decoration: const InputDecoration(labelText: 'الاسم'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: C.primary),
            onPressed: () async {
              await FirebaseService.updateProfile({'name': nameCtrl.text.trim()});
              Navigator.pop(dCtx);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

Future<void> _editCarDialog(BuildContext ctx, String plate, String carType, VehicleType vehicleType) async {
    final plateCtrl = TextEditingController(text: plate);
    VehicleType selectedType = vehicleType;
    
    await showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل بيانات المركبة', textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: plateCtrl, textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'رقم اللوحة'),
                ),
                const SizedBox(height: 16),
                const Text('نوع المركبة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 6,
                  children: VehicleType.values.map((type) {
                    final bool selected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(colors: [C.primary, C.secondary])
                              : null,
                          color: selected ? null : C.light,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? Colors.transparent : C.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.label,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? C.white : C.muted)),
                            const SizedBox(width: 4),
                            Icon(_vehicleTypeIcon(type),
                                size: 12, color: selected ? C.white : _vehicleTypeColor(type)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: C.primary),
              onPressed: () async {
                await FirebaseService.updateProfile({
                  'plate': plateCtrl.text.trim().toUpperCase(),
                  'vehicleType': selectedType.spotType,
                });
                Navigator.pop(dCtx);
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  IconData _vehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return FontAwesomeIcons.car;
      case VehicleType.vip:        return FontAwesomeIcons.crown;
      case VehicleType.motorcycle: return FontAwesomeIcons.motorcycle;
      case VehicleType.electric:   return FontAwesomeIcons.bolt;
      case VehicleType.disabled:   return FontAwesomeIcons.wheelchair;
    }
  }

  Color _vehicleTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return C.muted;
      case VehicleType.vip:        return Colors.amber.shade700;
      case VehicleType.motorcycle: return Colors.orange;
      case VehicleType.electric:   return Colors.green;
      case VehicleType.disabled:   return Colors.blue;
    }
  }

  Widget _buildLogoutBtn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await FirebaseService.signOut();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: C.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.error.withOpacity(0.3)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(FontAwesomeIcons.rightFromBracket, size: 14, color: C.error),
            SizedBox(width: 8),
            Text("تسجيل الخروج",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.error)),
          ]),
        ),
      ),
    );
  }
}
