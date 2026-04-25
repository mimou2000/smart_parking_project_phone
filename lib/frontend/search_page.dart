import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';
import 'dijkstra_service.dart';
import 'parking_zone.dart';
import 'pulsing_dot.dart';
import 'zone_card.dart';
import '../backend/app_locale.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  صفحة البحث
// ═══════════════════════════════════════════════════════════════════════════
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  ParkingZone? _selectedZone;
  bool _showAvailableOnly = false;
  String _sortBy = 'dijkstra'; // 'dijkstra', 'distance', 'price', 'spots'

  double? _userLat;
  double? _userLng;
  bool _locating = false;

  List<DijkstraResult> _dijkstraResults = [];
  int _refreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ══ جلب الموقع ══
  Future<void> _fetchLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack(tr('loc_disabled'), isError: true);
        setState(() => _locating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _snack(tr('loc_denied'), isError: true);
        setState(() => _locating = false);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _snack(tr('loc_blocked'), isError: true);
        await Geolocator.openAppSettings();
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locating = false;
        _refreshTrigger++;
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 14.5);
      _snack(tr('loc_set'), isError: false);
    } catch (e) {
      _snack(tr('loc_failed'), isError: true);
      setState(() => _locating = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? C.error : C.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Row(children: [
        Icon(
          isError
              ? FontAwesomeIcons.circleXmark
              : FontAwesomeIcons.locationDot,
          color: Colors.white,
          size: 13,
        ),
        const SizedBox(width: 8),
        Text(msg,
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      ]),
    ));
  }

  // ══ Stream: يحسب availableSpots الحقيقية من subcollection ══
  Stream<List<ParkingZone>> _zonesStream() {
    return FirebaseFirestore.instance
        .collection('zones')
        .snapshots()
        .asyncMap((snap) async {
      final futures = snap.docs.map((doc) async {
        final allSpotsSnap = await FirebaseFirestore.instance
            .collection('zones')
            .doc(doc.id)
            .collection('parking_spots')
            .get();

        final allSpots = allSpotsSnap.docs;

        // مقارنة الحالة بشكل غير حساس لحالة الأحرف
        final explicitAvailable = allSpots
            .where((d) {
          final s = (d.data()['status'] as String? ?? '').toUpperCase();
          return s == 'AVAILABLE';
        })
            .length;

        int availableCount;
        if (explicitAvailable == 0 && allSpots.isNotEmpty) {
          availableCount = allSpots.where((d) {
            final s = (d.data()['status'] as String? ?? 'AVAILABLE').toUpperCase();
            return s != 'BOOKED' && s != 'OCCUPIED' && s != 'RESERVED' && s != 'MAINTENANCE';
          }).length;
        } else {
          availableCount = explicitAvailable;
        }

        return ParkingZone.fromFirestoreWithAvailable(
          doc,
          availableSpots: availableCount,
          userLat: _userLat,
          userLng: _userLng,
        );
      });
      return Future.wait(futures);
    });
  }

  // ══ فلترة + ترتيب + اقتصار على أول 10 ══
  List<ParkingZone> _filter(List<ParkingZone> zones) {
    if (_userLat != null && _userLng != null && _sortBy == 'dijkstra') {
      _dijkstraResults = DijkstraService.findNearest(
        userLat: _userLat!,
        userLng: _userLng!,
        zones: zones,
      );
    }

    var list = zones.where((z) {
      final q = _searchCtrl.text;
      final matchSearch =
          q.isEmpty || z.name.contains(q) || z.address.contains(q);
      return matchSearch && (!_showAvailableOnly || z.isAvailable);
    }).toList();

    if (_sortBy == 'dijkstra' && _dijkstraResults.isNotEmpty) {
      final order = {
        for (int i = 0; i < _dijkstraResults.length; i++)
          _dijkstraResults[i].zone.id: i
      };
      list.sort(
              (a, b) => (order[a.id] ?? 999).compareTo(order[b.id] ?? 999));
    } else if (_sortBy == 'price') {
      list.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else if (_sortBy == 'spots') {
      list.sort((a, b) => b.availableSpots.compareTo(a.availableSpots));
    } else {
      list.sort((a, b) => a.distance.compareTo(b.distance));
    }

    if (list.length > 10) list = list.sublist(0, 10);

    return list;
  }

  String? _dijkstraLabel(String zoneId) {
    if (_dijkstraResults.isEmpty) return null;
    final r = _dijkstraResults.where((r) => r.zone.id == zoneId);
    if (r.isEmpty) return null;
    final res = r.first;
    final km = res.shortestPath.toStringAsFixed(1);
    return res.reachableByGraph ? '⬡ $km كم' : '≈ $km كم';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  build
  // ─────────────────────────────────────────────────────────────────────────
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
      body: StreamBuilder<List<ParkingZone>>(
        key: ValueKey(_refreshTrigger),
        stream: _zonesStream(),
        builder: (context, snap) {
          final zones = snap.data ?? [];
          final filtered = _filter(zones);

          return Column(
            children: [
              _buildHeader(zones.where((z) => z.isAvailable).length),
              _buildSearchBar(),
              _buildFilterRow(),
              Expanded(flex: 5, child: _buildMap(filtered)),
              Expanded(flex: 4, child: _buildZoneList(filtered, zones.length)),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Header
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(int available) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.panelDark1, C.panelDark2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 38),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tr('search_title'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(
                      _userLat != null
                          ? "${_userLat!.toStringAsFixed(3)}, ${_userLng!.toStringAsFixed(3)}"
                          : tr('city_default'),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ]),
              GestureDetector(
                onTap: _fetchLocation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _userLat != null
                        ? C.success.withOpacity(0.25)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: _userLat != null
                        ? Border.all(
                        color: C.success.withOpacity(0.6), width: 1.5)
                        : null,
                  ),
                  child: _locating
                      ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation(Colors.white)))
                      : Icon(
                    _userLat != null
                        ? FontAwesomeIcons.locationDot
                        : FontAwesomeIcons.locationCrosshairs,
                    color: _userLat != null
                        ? C.success
                        : Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Search Bar
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: C.panelDark2,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: TextField(
        controller: _searchCtrl,
        textAlign: TextAlign.right,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, color: C.dark),
        decoration: InputDecoration(
          hintText: tr('search_hint'),
          hintStyle:
          const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          filled: true,
          fillColor: C.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass,
              size: 14, color: C.muted),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
              icon: const Icon(Icons.close, size: 16, color: C.muted),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              })
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Filter Row
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: C.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _showAvailableOnly = !_showAvailableOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: _showAvailableOnly
                    ? const LinearGradient(
                    colors: [C.success, Color(0xFF059669)])
                    : null,
                color: _showAvailableOnly ? null : C.light,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _showAvailableOnly
                        ? Colors.transparent
                        : C.border,
                    width: 1.5),
              ),
              child: Row(children: [
                Icon(FontAwesomeIcons.filter,
                    size: 10,
                    color: _showAvailableOnly ? C.white : C.muted),
                const SizedBox(width: 5),
                Text(tr('available_only'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _showAvailableOnly ? C.white : C.muted)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip(tr('sort_smart'), 'dijkstra', FontAwesomeIcons.networkWired),
                const SizedBox(width: 6),
                _chip(tr('sort_nearest'), 'distance', FontAwesomeIcons.route),
                const SizedBox(width: 6),
                _chip(tr('sort_cheapest'), 'price', FontAwesomeIcons.tag),
                const SizedBox(width: 6),
                _chip(tr('sort_most'), 'spots', FontAwesomeIcons.squareParking),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String key, IconData icon) {
    final bool sel = _sortBy == key;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(colors: [C.primary, C.secondary])
              : null,
          color: sel ? null : C.light,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: sel ? Colors.transparent : C.border, width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, size: 10, color: sel ? C.white : C.muted),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: sel ? C.white : C.muted)),
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Map
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMap(List<ParkingZone> zones) {
    final center = _userLat != null
        ? LatLng(_userLat!, _userLng!)
        : (zones.isNotEmpty
        ? LatLng(zones[0].lat, zones[0].lng)
        : const LatLng(36.1901, 5.4108));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 14.5),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartparking.app',
        ),
        MarkerLayer(markers: [
          if (_userLat != null)
            Marker(
              width: 36,
              height: 36,
              point: LatLng(_userLat!, _userLng!),
              child: const PulsingDot(),
            ),
          ...zones.map((zone) {
            final bool sel = _selectedZone?.id == zone.id;
            return Marker(
              width: sel ? 100 : 80,
              height: 36,
              point: LatLng(zone.lat, zone.lng),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedZone = zone);
                  _mapController.move(LatLng(zone.lat, zone.lng), 15.5);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: zone.isAvailable
                          ? (sel
                          ? [C.primary, C.secondary]
                          : [C.success, const Color(0xFF059669)])
                          : [C.error, const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (zone.isAvailable ? C.success : C.error)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FontAwesomeIcons.squareParking,
                              color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            zone.isAvailable
                                ? "${zone.availableSpots}"
                                : tr('full'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),
                  ),
                ),
              ),
            );
          }),
        ]),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Zone List
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildZoneList(List<ParkingZone> filtered, int totalZonesCount) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.circleXmark,
                  size: 32, color: C.muted.withOpacity(0.4)),
              const SizedBox(height: 10),
              Text(tr('no_results'),
                  style: const TextStyle(color: C.muted, fontSize: 14)),
            ]),
      );
    }

    return Column(
      children: [
        Container(
          color: C.light,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // يمين في RTL: العنوان + Dijkstra badge
              Row(children: [
                Text(tr('nearby_spots'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: C.dark)),
                if (_sortBy == 'dijkstra' && _userLat != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [C.primary, C.secondary]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(children: [
                      Icon(FontAwesomeIcons.networkWired,
                          size: 9, color: Colors.white),
                      SizedBox(width: 4),
                      Text("Dijkstra",
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ]),
              // يسار في RTL: عداد النتائج
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${filtered.length}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: C.primary),
                    ),
                    TextSpan(
                        text: " ${tr('results_label')}",
                        style: const TextStyle(color: C.muted)),
                    if (totalZonesCount > 10 &&
                        filtered.length == 10 &&
                        _searchCtrl.text.isEmpty)
                      TextSpan(
                        text: " ${tr('top_10')}",
                        style: const TextStyle(
                            color: C.muted, fontSize: 10),
                      ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: C.light,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => ZoneCard(
                zone: filtered[i],
                isSelected: _selectedZone?.id == filtered[i].id,
                dijkstraLabel: _dijkstraLabel(filtered[i].id),
                sortBy: _sortBy,
                mapController: _mapController,
                onSelect: (z) => setState(() => _selectedZone = z),
                userLat: _userLat,
                userLng: _userLng,
              ),
            ),
          ),
        ),
      ],
    );
  }

// ──────────────────────────────────────────────────────────────────────────
//  Quick Feedback Sheet
}
