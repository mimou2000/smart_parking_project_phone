import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';
import '../backend/firebase_service.dart';
import '../backend/app_locale.dart';
import '../backend/guest_service.dart';
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

  // ── نوع مركبة المستخدم ──
  VehicleType _userVehicleType = VehicleType.standard;
  bool _filterByVehicleType = true;

  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _loadUserVehicleType();
  }

  Future<void> _loadUserVehicleType() async {
    // وضع الضيف: استخدم النوع الافتراضي بدون Firebase
    if (GuestService.isGuest) return;
    final vehicleType = await FirebaseService.getUserVehicleType();
    if (mounted) {
      setState(() => _userVehicleType = vehicleType);
    }
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
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
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
            child: GestureDetector(
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
                child: Row(children: [
                  const Icon(FontAwesomeIcons.diamondTurnRight,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 5),
                  Text(tr('direction'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
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
                prefillCategory: 'booking',
                onSubmitted: () {
                  setState(() => _showFeedback = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: C.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    content: Text(tr('thanks_rating'),
                        style: const TextStyle(
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
            Text(tr('coordinates'),
                style: const TextStyle(fontSize: 10, color: C.muted)),
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
              tr('available_spots_label'),
              FontAwesomeIcons.squareParking,
              C.success),
          _stat("${widget.zone.pricePerHour.toInt()} ${tr('currency')}", tr('price_per_hour_label'),
              FontAwesomeIcons.tag, C.warning),
          _stat("${widget.zone.distance} ${tr('distance_short')}", tr('distance_label'),
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
        // ── العنوان وفلتر نوع المركبة ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زر الفلتر
            GestureDetector(
              onTap: () => setState(() => _filterByVehicleType = !_filterByVehicleType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: _filterByVehicleType
                      ? const LinearGradient(colors: [C.primary, C.secondary])
                      : null,
                  color: _filterByVehicleType ? null : C.light,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _filterByVehicleType ? Colors.transparent : C.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filterByVehicleType ? tr('suitable_only') : tr('all_spots'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _filterByVehicleType ? C.white : C.muted,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      FontAwesomeIcons.filter,
                      size: 10,
                      color: _filterByVehicleType ? C.white : C.muted,
                    ),
                  ],
                ),
              ),
            ),
            Text(tr('choose_spot'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: C.dark)),
          ],
        ),
        // ── عرض نوع مركبة المستخدم ──
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "${tr('your_vehicle_type')}: ${_vehicleTypeLabelFor(_userVehicleType)}",
                style: TextStyle(
                  fontSize: 10,
                  color: _vehicleTypeColorFor(_userVehicleType),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _vehicleTypeIconFor(_userVehicleType),
                size: 11,
                color: _vehicleTypeColorFor(_userVehicleType),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<RealSpot>>(
          stream: GuestService.isGuest
              ? Stream.value(_buildGuestSpots())
              : FirebaseService.spotsStream(widget.zone.id),
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
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text("${tr('err_load_spots')}: ${snap.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: C.error, fontSize: 12)),
              );
            }
            if (snap.data?.isEmpty ?? true) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(tr('no_spots'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: C.muted, fontSize: 13)),
              );
            }

            // ── تطبيع جميع spotType للأحرف الكبيرة لضمان التوافق مع Firestore ──
            final spots = snap.data!.map((s) => RealSpot(
              docId:     s.docId,
              spotName:  s.spotName,
              spotType:  s.spotType.toUpperCase().trim(),
              status:    s.status,
              lat:       s.lat,
              lng:       s.lng,
            )).toList();

            // ترتيب المواقف: المناسبة لنوع المركبة أولاً ثم المتاحة
            final userSpotType = _userVehicleType.spotType.toUpperCase();
            final sortedSpots = List<RealSpot>.from(spots);
            sortedSpots.sort((a, b) {
              final aMatch = a.spotType == userSpotType ? 0 : 1;
              final bMatch = b.spotType == userSpotType ? 0 : 1;
              if (aMatch != bMatch) return aMatch.compareTo(bMatch);
              if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
              return 0;
            });

            // فلترة حسب نوع المركبة إذا كان الفلتر مفعلاً
            final filteredSpots = _filterByVehicleType
                ? sortedSpots.where((s) => _isSpotSuitableForVehicle(s.spotType)).toList()
                : sortedSpots;

            if (filteredSpots.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(FontAwesomeIcons.circleExclamation,
                        size: 24, color: C.warning.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text(tr('no_suitable_spots'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: C.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _filterByVehicleType = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: C.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tr('show_all_spots'),
                            style: const TextStyle(
                                color: C.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final grouped = <String, List<RealSpot>>{};
            for (final s in filteredSpots) {
              grouped.putIfAbsent(s.spotType, () => []).add(s);
            }

            // ترتيب المجموعات: المناسبة لنوع المركبة أولاً
            final sortedGroups = grouped.entries.toList();
            sortedGroups.sort((a, b) {
              final aMatch = a.key.toUpperCase() == userSpotType ? 0 : 1;
              final bMatch = b.key.toUpperCase() == userSpotType ? 0 : 1;
              return aMatch.compareTo(bMatch);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedGroups.map((entry) {
                final type = entry.key; // الآن دائماً أحرف كبيرة
                final list = entry.value;
                final color = _typeColor(type);
                final icon = _typeIcon(type);
                final isUserType = type == userSpotType; // مقارنة مباشرة بدون toUpperCase

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isUserType)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: C.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tr('suitable_badge'),
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: C.success)),
                            ),
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
                              border: isUserType
                                  ? Border.all(color: C.success, width: 1.5)
                                  : null,
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
          _legend(C.success, tr('legend_available')),
          const SizedBox(width: 12),
          _legend(C.error, tr('legend_booked')),
          const SizedBox(width: 12),
          _legend(C.primary, tr('legend_selected')),
        ]),
      ]),
    );
  }

  // ══ توليد مواقف تجريبية من spotTypes الخاصة بالمنطقة ══
  List<RealSpot> _buildGuestSpots() {
    final spots = <RealSpot>[];
    int index = 1;
    widget.zone.spotTypes.forEach((type, count) {
      for (int i = 0; i < count; i++) {
        final letter = String.fromCharCode(65 + (index ~/ 10));
        final num = index % 10 == 0 ? 10 : index % 10;
        // نصف المواقف محجوزة تجريبياً للواقعية
        final status = (index % 3 == 0) ? 'OCCUPIED' : 'AVAILABLE';
        spots.add(RealSpot(
          docId:    'demo_spot_$index',
          spotName: '$letter-$num',
          spotType: type,
            status: status == 'OCCUPIED' ? SpotStatus.occupied : SpotStatus.available,
          lat:      widget.zone.lat + (index * 0.00002),
          lng:      widget.zone.lng + (index * 0.00002),
        ));
        index++;
      }
    });
    return spots;
  }

  // ── التحقق من مناسبة الموقف لنوع المركبة ──
  bool _isSpotSuitableForVehicle(String spotType) {
    final userType = _userVehicleType.spotType.toUpperCase();
    final spot = spotType.toUpperCase();

    // المطابقة المباشرة
    if (spot == userType) return true;

    // السيارات العادية يمكنها استخدام مواقف STANDARD
    if (userType == 'STANDARD' && spot == 'STANDARD') return true;

    // السيارات الفاخرة يمكنها استخدام VIP و STANDARD
    if (userType == 'VIP' && (spot == 'VIP' || spot == 'STANDARD')) return true;

    // السيارات الكهربائية يمكنها استخدام ELECTRIC و STANDARD
    if (userType == 'ELECTRIC' && (spot == 'ELECTRIC' || spot == 'STANDARD')) return true;

    // ذوي الاحتياجات الخاصة يمكنهم استخدام DISABLED و STANDARD
    if (userType == 'DISABLED' && (spot == 'DISABLED' || spot == 'STANDARD')) return true;

    // الدراجات النارية فقط MOTORCYCLE
    if (userType == 'MOTORCYCLE' && spot == 'MOTORCYCLE') return true;

    return false;
  }

  // ── تسمية نوع المركبة ──
  String _vehicleTypeLabelFor(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return tr('vehicle_standard');
      case VehicleType.vip:        return tr('vehicle_vip');
      case VehicleType.motorcycle: return tr('vehicle_motorcycle');
      case VehicleType.electric:   return tr('vehicle_electric');
      case VehicleType.disabled:   return tr('vehicle_disabled');
    }
  }

  // ── أيقونة نوع المركبة ──
  IconData _vehicleTypeIconFor(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return FontAwesomeIcons.car;
      case VehicleType.vip:        return FontAwesomeIcons.crown;
      case VehicleType.motorcycle: return FontAwesomeIcons.motorcycle;
      case VehicleType.electric:   return FontAwesomeIcons.bolt;
      case VehicleType.disabled:   return FontAwesomeIcons.wheelchair;
    }
  }

  // ── لون نوع المركبة ──
  Color _vehicleTypeColorFor(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return C.muted;
      case VehicleType.vip:        return Colors.amber.shade700;
      case VehicleType.motorcycle: return Colors.orange;
      case VehicleType.electric:   return Colors.green;
      case VehicleType.disabled:   return Colors.blue;
    }
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
        Text(tr('booking_type'),
            style: const TextStyle(
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
                    Text(_bookingTypeLabel(type),
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
    final cur = tr('currency');
    switch (type) {
      case BookingType.hourly:
        return '${widget.zone.pricePerHour.toInt()} $cur/${tr('per_hour_short')}';
      case BookingType.daily:
        return '${widget.zone.pricePerDay.toInt()} $cur/${tr('per_day_short')}';
      case BookingType.weekly:
        return '${widget.zone.pricePerWeek.toInt()} $cur/${tr('per_week_short')}';
    }
  }

  String _bookingTypeLabel(BookingType type) {
    switch (type) {
      case BookingType.hourly: return tr('booking_type_hourly');
      case BookingType.daily:  return tr('booking_type_daily');
      case BookingType.weekly: return tr('booking_type_weekly');
    }
  }

  String _bookingTypeUnit(BookingType type) {
    switch (type) {
      case BookingType.hourly: return tr('unit_hour');
      case BookingType.daily:  return tr('unit_day');
      case BookingType.weekly: return tr('unit_week');
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
        Text("${tr('duration_label')} (${_bookingTypeUnit(_bookingType)})",
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
            Text(_bookingTypeUnit(_bookingType),
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
        _payRow(tr('summary_spot'),
            _selectedSpot != null ? _selectedSpot!.spotName : "—", C.white),
        const SizedBox(height: 6),
        if (_selectedSpot != null) ...[
          _payRow(tr('summary_type'), _selectedSpot!.spotType, Colors.white70),
          const SizedBox(height: 6),
        ],
        _payRow(tr('summary_booking_type'), _bookingType.label, Colors.white70),
        const SizedBox(height: 6),
        _payRow(tr('summary_duration'), "$_quantity ${_bookingType.unit}", C.white),
        const SizedBox(height: 6),
        _payRow(tr('summary_price_per'), "${_unitPrice().toInt()} ${tr('currency')}",
            Colors.white70),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24)),
        _payRow(tr('summary_total'), "${_total.toInt()} ${tr('currency')}", C.accent, large: true),
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
        // ── زر التوجه للموقف ──
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NavigationPage(
                zone: widget.zone,
                spotLat: _selectedSpot?.lat,
                spotLng: _selectedSpot?.lng,
                spotName: _selectedSpot?.spotName,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [C.primary, C.secondary],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: C.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FontAwesomeIcons.diamondTurnRight,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _selectedSpot?.lat != null && _selectedSpot!.lat != 0
                      ? "${tr('navigate_to_spot_at')} ${_selectedSpot!.spotName}"
                      : tr('navigate_to_zone'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── زر العودة للصفحة الرئيسية ──
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
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.circleCheck,
                      color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(tr('booking_confirmed_back'),
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
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.star, color: C.warning, size: 14),
                    SizedBox(width: 8),
                    Text(tr('rate_experience'),
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
            Text(tr('processing_booking'),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ] else ...[
            const Icon(FontAwesomeIcons.creditCard,
                color: Colors.white, size: 15),
            const SizedBox(width: 10),
            Text("${tr('pay_and_book')} ${_total.toInt()} ${tr('currency')}",
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
            child: Text(tr('feedback_later'),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(tr('feedback_banner_title'),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          Text(tr('feedback_banner_subtitle'),
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        const Icon(FontAwesomeIcons.solidStar, color: C.warning, size: 28),
      ]),
    );
  }

  // ══ تنفيذ الحجز ══
  Future<void> _processBooking() async {
    if (_selectedSpot == null) {
      setState(() => _errorMsg = tr('err_choose_spot'));
      return;
    }

    // وضع الضيف: محاكاة الحجز بدون Firebase
    if (GuestService.isGuest) {
      setState(() { _paying = true; _errorMsg = null; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() { _paying = false; _paid = true; });
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
        zoneLat:     widget.zone.lat,
        zoneLng:     widget.zone.lng,
        spotLat:     _selectedSpot!.lat,
        spotLng:     _selectedSpot!.lng,
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
        content: Row(children: [
          Icon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text(tr('booking_success'),
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
        ]),
      ));
    } catch (e) {
      setState(() {
        _paying = false;
        _errorMsg =
        "${tr('booking_failed')}: ${e.toString().replaceAll('Exception: ', '')}";
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