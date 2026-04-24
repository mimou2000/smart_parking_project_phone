import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import '../backend/firebase_service.dart';
import 'navigation_page.dart';
import 'parking_zone.dart';

// ════════════════════════════════════════════
//  صفحة الحجوزات
// ════════════════════════════════════════════
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});
  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.light,
      body: StreamBuilder<List<BookingRecord>>(
        stream: FirebaseService.myBookingsStream(),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final isLoading = snap.connectionState == ConnectionState.waiting;

          return Column(
            children: [
              _buildHeader(all),
              _buildTabs(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: C.primary))
                    : TabBarView(
                  controller: _tab,
                  children: [
                    _buildList(all, 'active'),
                    _buildList(all, 'completed'),
                    _buildList(all, 'cancelled'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<BookingRecord> all) {
    final activeCount = all.where((b) => b.status == 'active').length;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [C.panelDark1, C.panelDark2], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (activeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: C.success.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(FontAwesomeIcons.circleCheck, color: C.success, size: 11),
                    const SizedBox(width: 5),
                    Text("$activeCount نشط", style: const TextStyle(color: C.success, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text("${all.length} حجز",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              const Text("حجوزاتي",
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: C.white,
      child: TabBar(
        controller: _tab,
        labelColor: C.primary,
        unselectedLabelColor: C.muted,
        indicatorColor: C.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
        tabs: const [Tab(text: "النشطة"), Tab(text: "المكتملة"), Tab(text: "الملغاة")],
      ),
    );
  }

  Widget _buildList(List<BookingRecord> all, String status) {
    final list = all.where((b) => b.status == status).toList();
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.rectangleList, size: 36, color: C.muted.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text("لا توجد حجوزات", style: TextStyle(color: C.muted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  Widget _buildCard(BookingRecord b) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (b.status) {
      case 'active':
        statusColor = C.success; statusLabel = "نشط";  statusIcon = FontAwesomeIcons.circleCheck;    break;
      case 'completed':
        statusColor = C.primary; statusLabel = "مكتمل"; statusIcon = FontAwesomeIcons.flagCheckered; break;
      default:
        statusColor = C.error;   statusLabel = "ملغي";  statusIcon = FontAwesomeIcons.circleXmark;
    }

    // استخراج رقم الموقف من spotName (مثلاً "A-1" → "1") اختياري
    final spotDisplay = b.spotName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(statusIcon, size: 10, color: statusColor),
                  const SizedBox(width: 5),
                  Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(b.zoneName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)),
                Text(b.address,  style: const TextStyle(fontSize: 11, color: C.muted)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8, runSpacing: 6,
            children: [
              _detail(FontAwesomeIcons.clock,         b.durationLabel,          C.accent),
              _detail(FontAwesomeIcons.squareParking,  "موقف $spotDisplay",       C.primary),
              _detail(FontAwesomeIcons.moneyBill,      "${b.totalPrice.toInt()} دج", C.warning),
              _detail(FontAwesomeIcons.calendarDay,    b.dateLabel,               C.muted),
            ],
          ),
if (b.status == 'active') ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر إلغاء الحجز
              GestureDetector(
                onTap: () => _confirmCancel(b),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: C.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.error.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(FontAwesomeIcons.ban, size: 11, color: C.error),
                    SizedBox(width: 6),
                    Text("إلغاء الحجز",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.error)),
                  ]),
                ),
              ),
              // زر التوجه للموقف
              GestureDetector(
                onTap: () => _navigateToSpot(b),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.primary, C.secondary]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(FontAwesomeIcons.diamondTurnRight, size: 11, color: Colors.white),
                    SizedBox(width: 6),
                    Text("توجه للموقف",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

  void _navigateToSpot(BookingRecord b) {
    // إنشاء ParkingZone مؤقت للتوجيه
    final zone = ParkingZone(
      id: b.zoneId,
      name: b.zoneName,
      address: b.address,
      lat: b.zoneLat,
      lng: b.zoneLng,
      totalSpots: 0,
      availableSpots: 0,
      pricePerHour: 0,
      pricePerDay: 0,
      pricePerWeek: 0,
      distance: 0,
      spotTypes: {},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationPage(
          zone: zone,
          spotLat: b.spotLat,
          spotLng: b.spotLng,
          spotName: b.spotName,
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BookingRecord b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الإلغاء', textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟ سيتم استرداد الموقف.',
            textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: C.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.cancelBooking(b);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: C.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Text('تم إلغاء الحجز وتحرير الموقف',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: C.error,
          behavior: SnackBarBehavior.floating,
          content: Text('فشل الإلغاء: $e', style: const TextStyle(fontFamily: 'Tajawal')),
        ));
      }
    }
  }

  Widget _detail(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
