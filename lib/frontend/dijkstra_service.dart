import 'dart:math';

import 'parking_zone.dart';

// ════════════════════════════════════════════
//  خدمة Dijkstra — إيجاد أقرب مواقف
//
//  كيف تعمل:
//  - نبني رسماً بيانياً (graph) حيث كل منطقة وقوف هي عقدة (node)
//  - الحواف (edges) هي المسافة الجغرافية بين كل منطقتين
//  - نضيف عقدة وهمية "المستخدم" كنقطة البداية
//  - نُشغّل Dijkstra من موقع المستخدم
//  - النتيجة: قائمة المناطق مرتّبة حسب أقصر مسار
// ════════════════════════════════════════════

class DijkstraService {
  /// حساب المسافة بين نقطتين بـ Haversine (كم)
  static double haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// تشغيل Dijkstra من موقع المستخدم على شبكة المناطق
  ///
  /// [userLat] / [userLng] — موقع المستخدم
  /// [zones]              — قائمة مناطق الوقوف
  /// [maxEdgeKm]          — أقصى مسافة للحافة (افتراضي 5 كم)
  ///
  /// الإرجاع: قائمة [DijkstraResult] مرتّبة من الأقرب للأبعد
  static List<DijkstraResult> findNearest({
    required double userLat,
    required double userLng,
    required List<ParkingZone> zones,
    double maxEdgeKm = 5.0,
  }) {
    if (zones.isEmpty) return [];

    // ── بناء الرسم البياني ──────────────────────────────
    // العقد: 0 = المستخدم، 1..n = المناطق
    final n = zones.length;
    // adjacency list: nodeId → {neighborId: weight}
    final Map<int, Map<int, double>> graph = {};

    // عقدة المستخدم (0)
    graph[0] = {};
    for (int i = 0; i < n; i++) {
      final d = haversineKm(userLat, userLng, zones[i].lat, zones[i].lng);
      if (d <= maxEdgeKm) {
        graph[0]![i + 1] = d;
      }
    }

    // عقد المناطق (1..n)
    for (int i = 0; i < n; i++) {
      graph[i + 1] = {};
      // إضافة حافة رجوع للمستخدم
      final dToUser =
          haversineKm(userLat, userLng, zones[i].lat, zones[i].lng);
      if (dToUser <= maxEdgeKm) {
        graph[i + 1]![0] = dToUser;
      }
      // حواف بين المناطق
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final d = haversineKm(
            zones[i].lat, zones[i].lng, zones[j].lat, zones[j].lng);
        if (d <= maxEdgeKm) {
          graph[i + 1]![j + 1] = d;
        }
      }
    }

    // ── Dijkstra ────────────────────────────────────────
    final dist    = List<double>.filled(n + 1, double.infinity);
    final prev    = List<int>.filled(n + 1, -1);
    final visited = List<bool>.filled(n + 1, false);

    dist[0] = 0;

    for (int step = 0; step <= n; step++) {
      // اختر العقدة غير المزارة ذات أصغر مسافة (min-heap بسيط)
      int u = -1;
      for (int v = 0; v <= n; v++) {
        if (!visited[v] && (u == -1 || dist[v] < dist[u])) u = v;
      }
      if (u == -1 || dist[u] == double.infinity) break;
      visited[u] = true;

      final neighbors = graph[u] ?? {};
      for (final entry in neighbors.entries) {
        final v      = entry.key;
        final weight = entry.value;
        if (dist[u] + weight < dist[v]) {
          dist[v] = dist[u] + weight;
          prev[v] = u;
        }
      }
    }

    // ── بناء النتائج ────────────────────────────────────
    final results = <DijkstraResult>[];
    for (int i = 0; i < n; i++) {
      final nodeId = i + 1;
      final d = dist[nodeId];
      if (d == double.infinity) {
        // المنطقة بعيدة جداً — نضيفها بمسافة مباشرة
        results.add(DijkstraResult(
          zone:          zones[i],
          shortestPath:  haversineKm(userLat, userLng, zones[i].lat, zones[i].lng),
          pathNodeIds:   [0, nodeId],
          reachableByGraph: false,
        ));
      } else {
        results.add(DijkstraResult(
          zone:          zones[i],
          shortestPath:  double.parse(d.toStringAsFixed(2)),
          pathNodeIds:   _buildPath(prev, nodeId),
          reachableByGraph: true,
        ));
      }
    }

    results.sort((a, b) => a.shortestPath.compareTo(b.shortestPath));
    return results;
  }

  static List<int> _buildPath(List<int> prev, int target) {
    final path = <int>[];
    int cur = target;
    while (cur != -1) {
      path.add(cur);
      cur = prev[cur];
    }
    return path.reversed.toList();
  }
}

// ══ نتيجة Dijkstra لمنطقة واحدة ══
class DijkstraResult {
  final ParkingZone zone;
  final double      shortestPath;       // كم
  final List<int>   pathNodeIds;        // تسلسل العقد
  final bool        reachableByGraph;   // هل وصلت عبر الرسم؟

  const DijkstraResult({
    required this.zone,
    required this.shortestPath,
    required this.pathNodeIds,
    required this.reachableByGraph,
  });

  /// نسخة محدّثة من المنطقة مع المسافة المحسوبة بـ Dijkstra
  ParkingZone get zoneWithUpdatedDistance => ParkingZone(
    id:             zone.id,
    name:           zone.name,
    address:        zone.address,
    lat:            zone.lat,
    lng:            zone.lng,
    totalSpots:     zone.totalSpots,
    availableSpots: zone.availableSpots,
    pricePerHour:   zone.pricePerHour,
    pricePerDay:    zone.pricePerDay,
    pricePerWeek:   zone.pricePerWeek,
    distance:       shortestPath,
    spotTypes:      zone.spotTypes,
  );
}
