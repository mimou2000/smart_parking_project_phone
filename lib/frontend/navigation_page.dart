import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'main.dart';
import 'parking_zone.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  صفحة التوجيه الداخلي
//  - OSRM مجاني (بدون API key)
//  - مسار مرسوم على flutter_map
//  - تعليمات turn-by-turn نصية + صوت عربي (flutter_tts)
//  - تتبع موقع المستخدم لحظياً
// ═══════════════════════════════════════════════════════════════════════════

// ── نموذج خطوة التوجيه ──────────────────────────────────────────────
class NavStep {
  final String instruction; // التعليمة النصية
  final double distance;    // المسافة بالمتر
  final LatLng location;    // إحداثيات هذه الخطوة
  final String modifier;    // left / right / straight ...

  const NavStep({
    required this.instruction,
    required this.distance,
    required this.location,
    required this.modifier,
  });

  String get distanceLabel {
    if (distance < 1000) return '${distance.toInt()} م';
    return '${(distance / 1000).toStringAsFixed(1)} كم';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
class NavigationPage extends StatefulWidget {
  final ParkingZone zone;
  final double? startLat;
  final double? startLng;
  // ── إحداثيات الموقف المحدد (اختياري) ──
  final double? spotLat;
  final double? spotLng;
  final String? spotName;

  const NavigationPage({
    super.key,
    required this.zone,
    this.startLat,
    this.startLng,
    this.spotLat,
    this.spotLng,
    this.spotName,
  });

  // ── هل نتوجه للموقف المحدد أم للمنطقة ──
  bool get hasSpotCoordinates => spotLat != null && spotLng != null && spotLat != 0 && spotLng != 0;
  
  double get destinationLat => hasSpotCoordinates ? spotLat! : zone.lat;
  double get destinationLng => hasSpotCoordinates ? spotLng! : zone.lng;
  String get destinationName => hasSpotCoordinates ? "موقف ${spotName ?? ''}" : zone.name;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with TickerProviderStateMixin {
  // ── الخريطة ──
  final MapController _mapCtrl = MapController();

  // ── الموقع ──
  double? _userLat;
  double? _userLng;
  StreamSubscription<Position>? _posStream;

  // ── المسار ──
  List<LatLng> _routePoints = [];
  List<NavStep> _steps = [];
  double _totalDistanceKm = 0;
  double _totalDurationMin = 0;
  double _remainingDurationMin = 0; // ← وقت OSRM الحقيقي المتبقي
  bool _loading = true;
  String? _error;

  // ── التوجيه الحالي ──
  int _currentStepIndex = 0;
  bool _arrived = false;

  // ── TTS ──
  final FlutterTts _tts = FlutterTts();
  bool _ttsEnabled = true;
  bool _ttsReady = false;

  // ── Animation ──
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── إعادة تمركز تلقائي ──
  bool _autoCenter = true;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initTts();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _tts.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ══ تهيئة TTS ══════════════════════════════════════════════════════
  Future<void> _initTts() async {
    // ── تشخيص: اطبع كل ما هو متاح على الجهاز ──
    try {
      final langs = await _tts.getLanguages;
      debugPrint('=== TTS Languages available ===');
      for (final l in langs) debugPrint('  LANG: $l');
    } catch (e) {
      debugPrint('getLanguages error: $e');
    }

    try {
      final voices = await _tts.getVoices;
      debugPrint('=== TTS Voices available ===');
      for (final v in voices) debugPrint('  VOICE: $v');
    } catch (e) {
      debugPrint('getVoices error: $e');
    }

    // ── ضبط اللغة العربية ──
    // جرّب بالترتيب: 'ar' ثم 'ar-SA' ثم 'ar-EG'
    int result = await _tts.setLanguage('ar');
    debugPrint('setLanguage ar → $result'); // 1=نجح، 0=فشل

    if (result != 1) {
      result = await _tts.setLanguage('ar-SA');
      debugPrint('setLanguage ar-SA → $result');
    }
    if (result != 1) {
      result = await _tts.setLanguage('ar-EG');
      debugPrint('setLanguage ar-EG → $result');
    }

    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setErrorHandler((msg) => debugPrint('TTS error: $msg'));

    setState(() => _ttsReady = true);

    await Future.delayed(const Duration(milliseconds: 600));
    _speak('جاري تحضير التوجيه');
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled || !_ttsReady) return;
    await _tts.stop();
    final result = await _tts.speak(text);
    debugPrint('TTS speak "$text" → $result');
  }

  // ══ تتبع الموقع ═════════════════════════════════════════════════════
  Future<void> _startLocationTracking() async {
    // الموقع الابتدائي
    final initLat = widget.startLat;
    final initLng = widget.startLng;

    if (initLat != null && initLng != null) {
      setState(() {
        _userLat = initLat;
        _userLng = initLng;
      });
      await _fetchRoute(initLat, initLng);
    } else {
      // جلب الموقع أول مرة
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
        await _fetchRoute(pos.latitude, pos.longitude);
      } catch (e) {
        setState(() {
          _loading = false;
          _error = 'تعذّر تحديد موقعك';
        });
        return;
      }
    }

    // Stream تحديثات الموقع
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // تحديث كل 10 متر
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });

      if (_autoCenter) {
        _mapCtrl.move(LatLng(pos.latitude, pos.longitude), _mapCtrl.camera.zoom);
      }

      _updateCurrentStep(pos.latitude, pos.longitude);
    });
  }

  // ══ جلب المسار من OSRM ══════════════════════════════════════════════
  Future<void> _fetchRoute(double fromLat, double fromLng) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final destLat = widget.destinationLat;
    final destLng = widget.destinationLng;

    // OSRM Public API — مجاني بدون key
    // steps=true → تعليمات turn-by-turn
    // geometries=geojson → إحداثيات المسار
    // overview=full → المسار الكامل
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '$fromLng,$fromLat;$destLng,$destLat'
        '?steps=true&geometries=geojson&overview=full&annotations=false';

    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('OSRM error ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        throw Exception('لا يوجد مسار متاح');
      }

      final route = data['routes'][0] as Map<String, dynamic>;

      // ── إحداثيات المسار ──
      final coords = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      // ── المعلومات العامة ──
      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      // ── استخراج الخطوات ──
      final legs = route['legs'] as List;
      final steps = <NavStep>[];

      for (final leg in legs) {
        for (final step in (leg['steps'] as List)) {
          final maneuver = step['maneuver'] as Map<String, dynamic>;
          final loc = maneuver['location'] as List;
          final modifier = (maneuver['modifier'] ?? 'straight') as String;
          final type = (maneuver['type'] ?? '') as String;
          final stepDist = (step['distance'] as num).toDouble();

          final instruction = _buildInstruction(type, modifier, stepDist);
          if (instruction.isNotEmpty) {
            steps.add(NavStep(
              instruction: instruction,
              distance: stepDist,
              location: LatLng(
                (loc[1] as num).toDouble(),
                (loc[0] as num).toDouble(),
              ),
              modifier: modifier,
            ));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _routePoints = coords;
        _steps = steps;
        _totalDistanceKm = distanceM / 1000;
        _totalDurationMin = durationS / 60;
        _remainingDurationMin = durationS / 60; // ← من OSRM مباشرة
        _loading = false;
        _currentStepIndex = 0;
      });

      // تحريك الخريطة لتشمل المسار كاملاً
      if (coords.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(coords);
        _mapCtrl.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(60),
          ),
        );
      }

      // إعلان صوتي بالبداية
      if (steps.isNotEmpty) {
        _speak(
          'بدء التوجيه. المسافة الإجمالية '
              '${_totalDistanceKm.toStringAsFixed(1)} كيلومتر. '
              '${steps[0].instruction}',
        );
      }
    } on TimeoutException {
      setState(() {
        _loading = false;
        _error = 'انتهت مهلة الاتصال، تحقق من الإنترنت';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ══ تحديث الخطوة الحالية بناءً على موقع المستخدم ══════════════════
  void _updateCurrentStep(double lat, double lng) {
    if (_steps.isEmpty || _arrived) return;

    // فحص الوصول للوجهة النهائية (50 متر)
    final destDist = _distanceTo(lat, lng, widget.destinationLat, widget.destinationLng);
    if (destDist < 50) {
      setState(() => _arrived = true);
      _speak('لقد وصلت إلى وجهتك، ${widget.destinationName}');
      return;
    }

    // إيجاد الخطوة الأقرب
    for (int i = _currentStepIndex; i < _steps.length - 1; i++) {
      final stepDist = _distanceTo(lat, lng, _steps[i].location.latitude,
          _steps[i].location.longitude);

      // إذا اقتربنا من نقطة ال��حويل (30 متر) → انتقل للخطوة التالية
      if (stepDist < 30) {
        if (i + 1 < _steps.length && i + 1 != _currentStepIndex) {
          setState(() => _currentStepIndex = i + 1);
          _speak(_steps[i + 1].instruction);
        }
        break;
      }
    }
  }

  double _distanceTo(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// تنسيق المسافة: أقل من 1000 م → "350 م" / فوق 1000 م → "1.3 كم"
  String _formatDist(double meters) {
    if (meters < 1000) return '${meters.toInt()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  // ══ بناء التعليمة النصية العربية ════════════════════════════════════
  String _buildInstruction(String type, String modifier, double distance) {
    final distLabel = distance < 1000
        ? 'بعد ${distance.toInt()} متر'
        : 'بعد ${(distance / 1000).toStringAsFixed(1)} كيلومتر';

    switch (type) {
      case 'depart':
        return 'ابدأ التوجيه';
      case 'arrive':
        return 'لقد وصلت إلى وجهتك';
      case 'turn':
        switch (modifier) {
          case 'left':          return '$distLabel، انعطف يساراً';
          case 'right':         return '$distLabel، انعطف يميناً';
          case 'sharp left':    return '$distLabel، انعطف يساراً بشكل حاد';
          case 'sharp right':   return '$distLabel، انعطف يميناً بشكل حاد';
          case 'slight left':   return '$distLabel، احرف قليلاً للیسار';
          case 'slight right':  return '$distLabel، احرف قليلاً للیمین';
          case 'uturn':         return '$distLabel، استدر كلياً';
          default:              return '$distLabel، استمر';
        }
      case 'new name':
        return '$distLabel، استمر في الطريق';
      case 'merge':
        return '$distLabel، ادمج مع الطريق الرئيسي';
      case 'fork':
        return modifier == 'left'
            ? '$distLabel، خذ الاتجاه الأيسر عند التفرّع'
            : '$distLabel، خذ الاتجاه الأيمن عند التفرّع';
      case 'roundabout':
        return '$distLabel، ادخل الدوار';
      case 'exit roundabout':
        return 'اخرج من الدوار';
      case 'continue':
        return '$distLabel، واصل السير';
      default:
        return '';
    }
  }

  // ══ أيقونة الخطوة ═══════════════════════════════════════════════════
  IconData _stepIcon(String modifier) {
    switch (modifier) {
      case 'left':
      case 'sharp left':
      case 'slight left':   return Icons.turn_left;
      case 'right':
      case 'sharp right':
      case 'slight right':  return Icons.turn_right;
      case 'uturn':         return Icons.u_turn_left;
      case 'roundabout':    return Icons.roundabout_left;
      default:              return Icons.straight;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  build
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── الخريطة ──
          _buildMap(),

          // ── شريط المعلومات العلوي ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopBar(),
          ),

          // ── شريط تقدم المسار ──
          if (!_loading && _error == null && _totalDistanceKm > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: _buildProgressBar(remainingKm: (() {
                if (_userLat == null) return _totalDistanceKm;
                final d = Geolocator.distanceBetween(
                    _userLat!, _userLng!, widget.destinationLat, widget.destinationLng);
                return d / 1000;
              })()),
            ),
          if (!_loading && _error == null && !_arrived)
            Positioned(
              bottom: 180, left: 16, right: 16,
              child: _buildCurrentStepCard(),
            ),

          // ── بطاقة الوصول ──
          if (_arrived)
            Positioned(
              bottom: 180, left: 16, right: 16,
              child: _buildArrivalCard(),
            ),

          // ── شريط التقدم السفلي ──
          if (!_loading && _error == null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildBottomBar(),
            ),

          // ── شاشة التحميل ──
          if (_loading) _buildLoadingOverlay(),

          // ── شاشة الخطأ ──
          if (_error != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  // ══ الخريطة ══════════════════════════════════════════════════════════
  Widget _buildMap() {
    final center = _userLat != null
        ? LatLng(_userLat!, _userLng!)
        : LatLng(widget.destinationLat, widget.destinationLng);

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) setState(() => _autoCenter = false);
        },
      ),
      children: [
        // طبقة الخريطة
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartparking.app',
        ),

        // خط المسار
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // ظل المسار
              Polyline(
                points: _routePoints,
                strokeWidth: 8,
                color: Colors.black.withOpacity(0.2),
              ),
              // المسار الأساسي
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: C.primary,
                borderStrokeWidth: 1.5,
                borderColor: Colors.white.withOpacity(0.6),
              ),
            ],
          ),

        // العلامات
        MarkerLayer(markers: [
          // موقع المستخدم
          if (_userLat != null)
            Marker(
              width: 44,
              height: 44,
              point: LatLng(_userLat!, _userLng!),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40 * _pulseAnim.value,
                      height: 40 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: C.primary.withOpacity(0.2 * _pulseAnim.value),
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: C.primary,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: C.primary.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // وجهة الموقف
          Marker(
            width: 56,
            height: 56,
            point: LatLng(widget.destinationLat, widget.destinationLng),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [C.primary, C.secondary]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.squareParking,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // نقاط التحويل (الخطوات)
          ..._steps.asMap().entries
              .where((e) => e.key > _currentStepIndex)
              .take(3)
              .map((e) => Marker(
            width: 28,
            height: 28,
            point: e.value.location,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: C.accent, width: 2),
              ),
              child: Icon(
                _stepIcon(e.value.modifier),
                size: 12,
                color: C.accent,
              ),
            ),
          )),
        ]),
      ],
    );
  }

  // ══ الشريط العلوي ═════════════════════════════════════════════════════
  Widget _buildTopBar() {
    // المسافة المتبقية الكلية
    double remainingKm = _totalDistanceKm;
    if (_userLat != null) {
      final d = Geolocator.distanceBetween(
          _userLat!, _userLng!, widget.destinationLat, widget.destinationLng);
      remainingKm = d / 1000;
    }
    final distLabel = _formatDist(remainingKm * 1000);

    final ratio = _totalDistanceKm > 0 ? remainingKm / _totalDistanceKm : 1.0;
    final remainingMin = (_totalDurationMin * ratio).round();
    final timeLabel = remainingMin >= 60
        ? '${remainingMin ~/ 60}س ${remainingMin % 60}د'
        : '$remainingMin د';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              // زر الإغلاق
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(FontAwesomeIcons.xmark,
                      color: Colors.white, size: 14),
                ),
              ),

              const SizedBox(width: 12),

              // اسم الوجهة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.zone.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!_loading && _error == null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // الوقت
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: C.accent.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(children: [
                              const Icon(Icons.access_time,
                                  color: Colors.white70, size: 11),
                              const SizedBox(width: 4),
                              Text(timeLabel,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                          const SizedBox(width: 6),
                          // المسافة المتبقية — واضحة وكبيرة
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: C.primary.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.white30, width: 1),
                            ),
                            child: Row(children: [
                              const Icon(Icons.route,
                                  color: Colors.white, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                distLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // زر الصوت
              GestureDetector(
                onTap: () => setState(() => _ttsEnabled = !_ttsEnabled),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _ttsEnabled
                        ? C.primary.withOpacity(0.8)
                        : Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _ttsEnabled ? C.primary : Colors.white24),
                  ),
                  child: Icon(
                    _ttsEnabled
                        ? FontAwesomeIcons.volumeHigh
                        : FontAwesomeIcons.volumeXmark,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // زر إعادة التمركز
              GestureDetector(
                onTap: () {
                  setState(() => _autoCenter = true);
                  if (_userLat != null) {
                    _mapCtrl.move(
                        LatLng(_userLat!, _userLng!), _mapCtrl.camera.zoom);
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _autoCenter
                        ? C.success.withOpacity(0.8)
                        : Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _autoCenter ? C.success : Colors.white24),
                  ),
                  child: const Icon(FontAwesomeIcons.locationDot,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══ شريط تقدم المسار ════════════════════════════════════════════════
  Widget _buildProgressBar({required double remainingKm}) {
    final covered = (_totalDistanceKm - remainingKm).clamp(0.0, _totalDistanceKm);
    final progress = _totalDistanceKm > 0 ? covered / _totalDistanceKm : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // المسافة المتبقية
              Text(
                '${_formatDist(remainingKm * 1000)} متبقية',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'من ${_formatDist(_totalDistanceKm * 1000)}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                progress > 0.8 ? C.success : C.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // المسافة المقطوعة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% مكتمل',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
              Text(
                'قطعت ${_formatDist(covered * 1000)}',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══ بطاقة الخطوة الحالية ════════════════════════════════════════════
  Widget _buildCurrentStepCard() {
    if (_steps.isEmpty) return const SizedBox.shrink();
    final step = _steps[_currentStepIndex];
    final isLast = _currentStepIndex == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          // أيقونة التوجيه
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [C.primary, C.secondary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_stepIcon(step.modifier),
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),

          // التعليمة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  step.instruction,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: C.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLast && _currentStepIndex + 1 < _steps.length)
                      Text(
                        'ثم: ${_steps[_currentStepIndex + 1].instruction}',
                        style: const TextStyle(
                            fontSize: 10, color: C.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // المسافة
          Column(
            children: [
              Text(
                step.distanceLabel.split(' ')[0],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: C.primary,
                ),
              ),
              Text(
                step.distanceLabel.split(' ').length > 1
                    ? step.distanceLabel.split(' ')[1]
                    : '',
                style: const TextStyle(fontSize: 11, color: C.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══ بطاقة الوصول ════════════════════════════════════════════════════
  Widget _buildArrivalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [C.success, Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: C.success.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('إغلاق',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('وصلت! 🎉',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Text('تم الوصول إلى الموقف',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Icon(FontAwesomeIcons.circleCheck,
              color: Colors.white, size: 36),
        ],
      ),
    );
  }

  // ══ الشريط السفلي ════════════════════════════════════════════════════
  Widget _buildBottomBar() {
    // المسافة المتبقية الحقيقية
    double remainingKm = _totalDistanceKm;
    if (_userLat != null) {
      final d = Geolocator.distanceBetween(
          _userLat!, _userLng!, widget.destinationLat, widget.destinationLng);
      remainingKm = d / 1000;
    }

    // الوقت المتبقي: نسبة من وقت OSRM الأصلي
    final ratio = _totalDistanceKm > 0 ? remainingKm / _totalDistanceKm : 1.0;
    final remainingMin = (_remainingDurationMin * ratio).round();
    final timeLabel = remainingMin >= 60
        ? '${remainingMin ~/ 60}س ${remainingMin % 60}د'
        : '$remainingMin د';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مؤشر السحب
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: C.border, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoTile(
                  _formatDist(remainingKm * 1000),
                  'متبقية',
                  FontAwesomeIcons.route,
                  C.primary),
              _infoTile(
                  timeLabel,
                  'الوقت المتبقي',
                  FontAwesomeIcons.clock,
                  C.accent),
              _infoTile(
                  '${_currentStepIndex + 1}/${_steps.length}',
                  'خطوة',
                  FontAwesomeIcons.listOl,
                  C.warning),
              // زر إعادة الحساب
              GestureDetector(
                onTap: () {
                  if (_userLat != null) _fetchRoute(_userLat!, _userLng!);
                },
                child: Column(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: C.light,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.border),
                    ),
                    child: const Icon(FontAwesomeIcons.arrowsRotate,
                        size: 16, color: C.muted),
                  ),
                  const SizedBox(height: 4),
                  const Text('إعادة',
                      style: TextStyle(fontSize: 10, color: C.muted)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String val, String label, IconData icon, Color color) {
    return Column(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(height: 4),
      Text(val,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      Text(label,
          style: const TextStyle(fontSize: 9, color: C.muted)),
    ]);
  }

  // ══ شاشة التحميل ════════════════════════════════════════════════════
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: C.primary, strokeWidth: 3),
            const SizedBox(height: 16),
            const Text('جاري حساب المسار...',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: C.dark)),
            const SizedBox(height: 6),
            Text('التوجيه إلى ${widget.destinationName}',
                style: const TextStyle(fontSize: 11, color: C.muted)),
          ]),
        ),
      ),
    );
  }

  // ══ شاشة الخطأ ══════════════════════════════════════════════════════
  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(FontAwesomeIcons.triangleExclamation,
                color: C.error, size: 36),
            const SizedBox(height: 14),
            Text(_error ?? 'خطأ غير معروف',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: C.dark, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: C.light,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.border),
                    ),
                    child: const Text('رجوع',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: C.muted, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_userLat != null) _fetchRoute(_userLat!, _userLng!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [C.primary, C.secondary]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('إعادة المحاولة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
