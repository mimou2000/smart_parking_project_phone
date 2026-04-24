import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';
import '../backend/firebase_service.dart';
import 'home_shell.dart';
import 'feedback_page.dart';
import 'navigation_page.dart';
import 'parking_zone.dart';

// ════════════════════════════════════════════
//  صفحة الحجز — دعم ساعي / يومي / أسبوعي
// ════════════════════════════════════════════
class BookingPage extends StatefulWidget {
  final ParkingZone zone;
  const BookingPage({super.key, required this.zone});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  // ── نوع الحجز ──
  BookingType _bookingType = BookingType.hourly;
  int _quantity = 1;

  RealSpot? _selectedSpot;
  bool _paying = false;
  bool _paid = false;
  bool _showFeedback = false;
  String? _errorMsg;

  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── حساب السعر حسب نوع الحجز ──
  double get _total {
    switch (_bookingType) {
      case BookingType.hourly:
        return _quantity * widget.zone.pricePerHour;
      case BookingType.daily:
        return _quantity * widget.zone.pricePerDay;
      case BookingType.weekly:
        return _quantity * widget.zone.pricePerWeek;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.light,
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            _buildMapSection(),
            Expanded(child: _buildDetails()),
          ],
        ),
      ),
    );
  }

  // ══ الخريطة ══
  Widget _buildMapSection() {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.zone.lat, widget.zone.lng),
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartparking.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  width: 50,
                  height: 50,
                  point: LatLng(widget.zone.lat, widget.zone.lng),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient:
                      LinearGradient(colors: [C.primary, C.secondary]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(FontAwesomeIcons.squareParking,
                        color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: C.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12), blurRadius: 8)
                  ],
                ),
                child: const Icon(FontAwesomeIcons.arrowRight,
                    size: 14, color: C.dark),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Row(children: [
              // ← جديد: زر توجيه الموقف (يظهر فقط عند اختيار موقف)
              if (_selectedSpot != null) ...[
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NavigationPage(
                        zone: widget.zone,
                        destLat: _selectedSpot!.lat,
                        destLng: _selectedSpot!.lng,
                        destinationName: _selectedSpot!.spotName,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: C.primary,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(FontAwesomeIcons.diamondTurnRight,
                          color: Colors.white, size: 10),
                      SizedBox(width: 3),
                      Text("الموقف",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // زر توجيه المنطقة
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NavigationPage(zone: widget.zone),
                  ),
                ),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: C.accent, borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(FontAwesomeIcons.diamondTurnRight,
                        color: Colors.white, size: 12),
                    SizedBox(width: 5),
                    Text("الاتجاه",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ══ التفاصيل ══
  Widget _buildDetails() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoCard(),
          _buildSpotSelector(),
          _buildBookingTypeSelector(),
          _buildDurationSelector(),
          _buildPaymentSummary(),
          if (_errorMsg != null)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.error.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_errorMsg!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12,
                            color: C.error,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Icon(FontAwesomeIcons.circleXmark,
                      size: 13, color: C.error),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildBookBtn(),
          ),
          if (_paid && _showFeedback) ...[
            _buildFeedbackBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: QuickFeedbackForm(
                prefillCategory: 'تجربة الحجز',
                onSubmitted: () {
                  setState(() => _showFeedback = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: C.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    content: const Text("شكراً على تقييمك!",
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700)),
                  ));
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ══ معلومات المنطقة ══
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("الإحداثيات",
                style: TextStyle(fontSize: 10, color: C.muted)),
            Text(
              "${widget.zone.lat.toStringAsFixed(4)}, "
                  "${widget.zone.lng.toStringAsFixed(4)}",
              style: const TextStyle(
                  fontSize: 11,
                  color: C.accent,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(widget.zone.name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: C.dark)),
            Text(widget.zone.address,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: C.muted)),
          ]),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(
              "${widget.zone.availableSpots}/${widget.zone.totalSpots}",
              "مواقف متاحة",
              FontAwesomeIcons.squareParking,
              C.success),
          _stat("${widget.zone.pricePerHour.toInt()} دج", "السعر/ساعة",
              FontAwesomeIcons.tag, C.warning),
          _stat("${widget.zone.distance} كم", "المسافة",
              FontAwesomeIcons.route, C.accent),
        ]),
      ]),
    );
  }

  Widget _stat(String val, String label, IconData icon, Color color) =>
      Column(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 5),
        Text(val,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: C.muted)),
      ]);

  // ══ اختيار الموقف ══
  Widget _buildSpotSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text("اختر موقفك",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: C.dark)),
        const SizedBox(height: 10),
        StreamBuilder<List<RealSpot>>(
          stream: FirebaseService.spotsStream(widget.zone.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: C.primary),
                ),
              );
            }
            if (snap.hasError || (snap.data?.isEmpty ?? true)) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text("لا توجد مواقف متاحة",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.muted, fontSize: 13)),
              );
            }

            final spots = snap.data!;
            final grouped = <String, List<RealSpot>>{};
            for (final s in spots) {
              grouped.putIfAbsent(s.spotType, () => []).add(s);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: grouped.entries.map((entry) {
                final type = entry.key;
                final list = entry.value;
                final color = _typeColor(type);
                final icon = _typeIcon(type);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(type,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: color)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(icon, size: 11, color: color),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: list.map((spot) {
                        final sel = _selectedSpot?.docId == spot.docId;
                        final ok = spot.isAvailable;

                        return GestureDetector(
                          onTap: ok
                              ? () => setState(() {
                            _selectedSpot = spot;
                            _errorMsg = null;
                          })
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? const LinearGradient(
                                  colors: [C.primary, C.secondary])
                                  : null,
                              color: !ok
                                  ? C.error.withOpacity(0.12)
                                  : sel
                                  ? null
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: sel
                                    ? C.primary
                                    : !ok
                                    ? C.error.withOpacity(0.4)
                                    : color.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                spot.spotName,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: sel
                                      ? C.white
                                      : !ok
                                      ? C.error
                                      : color,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            );
          },
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _legend(C.success, "متاح"),
          const SizedBox(width: 12),
          _legend(C.error, "محجوز"),
          const SizedBox(width: 12),
          _legend(C.primary, "مختار"),
        ]),
      ]),
    );
  }

  // ══ اختيار نوع الحجز ══
  Widget _buildBookingTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text("نوع الحجز",
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 12),
        Row(
          children: BookingType.values.map((type) {
            final sel = _bookingType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _bookingType = type;
                  _quantity = 1;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(
                        colors: [C.primary, C.secondary])
                        : null,
                    color: sel ? null : C.light,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? Colors.transparent : C.border,
                        width: 1.5),
                  ),
                  child: Column(children: [
                    Icon(
                      type == BookingType.hourly
                          ? FontAwesomeIcons.clock
                          : type == BookingType.daily
                          ? FontAwesomeIcons.calendarDay
                          : FontAwesomeIcons.calendarWeek,
                      size: 14,
                      color: sel ? C.white : C.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(type.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? C.white : C.muted)),
                    Text(
                      _priceForType(type),
                      style: TextStyle(
                          fontSize: 10,
                          color: sel
                              ? Colors.white70
                              : C.muted.withOpacity(0.7)),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  String _priceForType(BookingType type) {
    switch (type) {
      case BookingType.hourly:
        return '${widget.zone.pricePerHour.toInt()} دج/س';
      case BookingType.daily:
        return '${widget.zone.pricePerDay.toInt()} دج/ي';
      case BookingType.weekly:
        return '${widget.zone.pricePerWeek.toInt()} دج/أ';
    }
  }

  // ══ الكمية ══
  Widget _buildDurationSelector() {
    final max = _bookingType.maxQuantity;
    final quickValues = _bookingType == BookingType.hourly
        ? [1, 2, 3, 6, 12]
        : _bookingType == BookingType.daily
        ? [1, 3, 7, 14, 30]
        : [1, 2, 3, 4];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text("مدة الحجز (${_bookingType.unit})",
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _circleBtn(FontAwesomeIcons.plus,
                  () { if (_quantity < max) setState(() => _quantity++); }),
          const SizedBox(width: 24),
          Column(children: [
            Text("$_quantity",
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: C.primary)),
            Text(_bookingType.unit,
                style: const TextStyle(fontSize: 12, color: C.muted)),
          ]),
          const SizedBox(width: 24),
          _circleBtn(FontAwesomeIcons.minus,
                  () { if (_quantity > 1) setState(() => _quantity--); }),
        ]),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: quickValues.map((v) {
            final sel = _quantity == v;
            return GestureDetector(
              onTap: () => setState(() => _quantity = v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(colors: [C.primary, C.secondary])
                      : null,
                  color: sel ? null : C.light,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: sel ? Colors.transparent : C.border,
                      width: 1.5),
                ),
                child: Text("$v",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? C.white : C.muted)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: C.light,
        shape: BoxShape.circle,
        border: Border.all(color: C.border, width: 1.5),
      ),
      child: Icon(icon, size: 13, color: C.dark),
    ),
  );

  // ══ ملخص الدفع ══
  Widget _buildPaymentSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [C.panelDark1, C.panelDark2],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        _payRow("الموقف",
            _selectedSpot != null ? _selectedSpot!.spotName : "—", C.white),
        const SizedBox(height: 6),
        if (_selectedSpot != null) ...[
          _payRow("النوع", _selectedSpot!.spotType, Colors.white70),
          const SizedBox(height: 6),
        ],
        _payRow("نوع الحجز", _bookingType.label, Colors.white70),
        const SizedBox(height: 6),
        _payRow("المدة", "$_quantity ${_bookingType.unit}", C.white),
        const SizedBox(height: 6),
        _payRow("السعر/${_bookingType.unit}", "${_unitPrice().toInt()} دج",
            Colors.white70),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24)),
        _payRow("الإجمالي", "${_total.toInt()} دج", C.accent, large: true),
      ]),
    );
  }

  double _unitPrice() {
    switch (_bookingType) {
      case BookingType.hourly:  return widget.zone.pricePerHour;
      case BookingType.daily:   return widget.zone.pricePerDay;
      case BookingType.weekly:  return widget.zone.pricePerWeek;
    }
  }

  Widget _payRow(String label, String value, Color color,
      {bool large = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: large ? 16 : 13,
                fontWeight:
                large ? FontWeight.w900 : FontWeight.w600)),
        Text(label,
            style: TextStyle(
                color: Colors.white70,
                fontSize: large ? 14 : 12,
                fontWeight:
                large ? FontWeight.w700 : FontWeight.normal)),
      ]);

  // ══ زر الحجز ══
  Widget _buildBookBtn() {
    if (_paid) {
      return Column(children: [
        GestureDetector(
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell()),
                (_) => false,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: C.success,
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.circleCheck,
                      color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text("تم تأكيد الحجز — اضغط للعودة",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
          ),
        ),
        if (!_showFeedback) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showFeedback = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: C.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.warning.withOpacity(0.4)),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.star, color: C.warning, size: 14),
                    SizedBox(width: 8),
                    Text("قيّم تجربتك",
                        style: TextStyle(
                            color: C.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]),
            ),
          ),
        ],
      ]);
    }

    return GestureDetector(
      onTap: _paying ? null : _processBooking,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [C.primary, C.secondary]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: C.primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_paying) ...[
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation(Colors.white))),
            const SizedBox(width: 10),
            const Text("جاري تأكيد الحجز...",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ] else ...[
            const Icon(FontAwesomeIcons.creditCard,
                color: Colors.white, size: 15),
            const SizedBox(width: 10),
            Text("ادفع ${_total.toInt()} دج واحجز",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }

  // ══ بانر التقييم ══
  Widget _buildFeedbackBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(14),
      ),
      child:
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: () => setState(() => _showFeedback = false),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text("لاحقاً",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("كيف كانت تجربتك؟",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          Text("قيّم تجربة الحجز الآن",
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        const Icon(FontAwesomeIcons.solidStar, color: C.warning, size: 28),
      ]),
    );
  }

  // ══ تنفيذ الحجز ══
  Future<void> _processBooking() async {
    if (_selectedSpot == null) {
      setState(() => _errorMsg = 'يرجى اختيار موقف أولاً');
      return;
    }

    setState(() {
      _paying = true;
      _errorMsg = null;
    });

    try {
      await FirebaseService.createBooking(
        zoneId:      widget.zone.id,
        zoneName:    widget.zone.name,
        address:     widget.zone.address,
        spotId:      _selectedSpot!.docId,
        spotName:    _selectedSpot!.spotName,
        spotType:    _selectedSpot!.spotType,
        bookingType: _bookingType,
        quantity:    _quantity,
        totalPrice:  _total,
      );

      if (!mounted) return;
      setState(() {
        _paying = false;
        _paid = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: C.success,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(children: [
          Icon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text("تم تأكيد الحجز بنجاح!",
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
        ]),
      ));
    } catch (e) {
      setState(() {
        _paying = false;
        _errorMsg =
        'فشل الحجز: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  // ══ دوال مساعدة ══
  Widget _legend(Color color, String label) => Row(children: [
    Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
    ),
    const SizedBox(width: 4),
    Text(label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  ]);

  Color _typeColor(String type) {
    const map = {
      'VIP':            Color(0xFFD97706),
      'عادي':           Color(0xFF6366F1),
      'دراجة':          Color(0xFFF59E0B),
      'ذوي احتياجات':  Color(0xFF3B82F6),
      'كهربائي':        Color(0xFF10B981),
      'STANDARD':       Color(0xFF6366F1),
      'DISABLED':       Color(0xFF3B82F6),
      'ELECTRIC':       Color(0xFF10B981),
      'MOTORCYCLE':     Color(0xFFF59E0B),
    };
    return map[type] ?? C.muted;
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'VIP':             return FontAwesomeIcons.crown;
      case 'كهربائي':
      case 'ELECTRIC':        return FontAwesomeIcons.bolt;
      case 'ذوي احتياجات':
      case 'DISABLED':        return FontAwesomeIcons.wheelchair;
      case 'دراجة':
      case 'MOTORCYCLE':      return FontAwesomeIcons.bicycle;
      default:                return FontAwesomeIcons.car;
    }
  }
}
