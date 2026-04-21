import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';
import 'booking_page.dart';
import 'navigation_page.dart';
import 'parking_zone.dart';
import 'spot_type_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  بطاقة المنطقة (Zone Card) + chip مساعد
// ═══════════════════════════════════════════════════════════════════════════

class ZoneCard extends StatelessWidget {
  final ParkingZone zone;
  final bool isSelected;
  final String? dijkstraLabel;
  final String sortBy;
  final MapController mapController;
  final ValueChanged<ParkingZone> onSelect;
  final double? userLat;
  final double? userLng;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.isSelected,
    required this.dijkstraLabel,
    required this.sortBy,
    required this.mapController,
    required this.onSelect,
    this.userLat,
    this.userLng,
  });

  void _openNavigation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationPage(
          zone: zone,
          startLat: userLat,
          startLng: userLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = isSelected;
    final dLabel = dijkstraLabel;

    return GestureDetector(
      onTap: () {
        onSelect(zone);
        mapController.move(LatLng(zone.lat, zone.lng), 15.5);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? C.primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: sel
                  ? C.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: sel ? 12 : 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(children: [
          // أزرار الحجز والاتجاهات
          Column(
            children: [
              GestureDetector(
                onTap: zone.isAvailable
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BookingPage(zone: zone)))
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: zone.isAvailable
                        ? const LinearGradient(
                            colors: [C.primary, C.secondary])
                        : null,
                    color: zone.isAvailable ? null : C.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    zone.isAvailable ? "احجز" : "ممتلئ",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: zone.isAvailable ? C.white : C.muted),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _openNavigation(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: C.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(FontAwesomeIcons.directions,
                      size: 16, color: C.primary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(zone.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: C.dark)),
                const SizedBox(height: 3),
                Text(zone.address,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: C.muted)),
                const SizedBox(height: 6),
                // أنواع المواقف
                if (zone.spotTypes.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 4,
                    children: zone.spotTypes.entries.map((entry) {
                      final letter = getSpotTypeLetter(entry.key);
                      final count = entry.value;
                      final color = getSpotTypeColor(entry.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(getSpotTypeIcon(entry.key),
                                size: 9, color: color),
                            const SizedBox(width: 4),
                            Text(
                              '$letter ×$count',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: color),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 6),
                // معلومات إضافية
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip2(
                      zone.isAvailable
                          ? "${zone.availableSpots}/${zone.totalSpots}"
                          : "ممتلئ",
                      FontAwesomeIcons.squareParking,
                      zone.isAvailable ? C.success : C.error,
                    ),
                    _chip2("${zone.pricePerHour.toInt()} دج/س",
                        FontAwesomeIcons.tag, C.warning),
                    if (dLabel != null && sortBy == 'dijkstra')
                      _chip2(dLabel, FontAwesomeIcons.networkWired, C.primary)
                    else
                      _chip2("${zone.distance} كم",
                          FontAwesomeIcons.route, C.accent),
                  ],
                ),
              ],
            ),
          ),
          // أيقونة الموقف
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: zone.isAvailable
                    ? [C.success, const Color(0xFF059669)]
                    : [C.error, const Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FontAwesomeIcons.squareParking,
                color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }

  Widget _chip2(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
