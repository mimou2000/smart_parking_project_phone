import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  دوال مساعدة لأنواع المواقف
// ═══════════════════════════════════════════════════════════════════════════

String getSpotTypeLetter(String type) {
  const map = {
    'STANDARD': 'A',
    'VIP': 'B',
    'MOTORCYCLE': 'C',
    'DISABLED': 'D',
    'ELECTRIC': 'E',
  };
  return map[type] ?? type[0];
}

Color getSpotTypeColor(String type) {
  switch (type) {
    case 'VIP':
      return Colors.amber.shade700;
    case 'ELECTRIC':
      return Colors.green;
    case 'DISABLED':
      return Colors.blue;
    case 'MOTORCYCLE':
      return Colors.orange;
    default:
      return C.muted;
  }
}

IconData getSpotTypeIcon(String type) {
  switch (type) {
    case 'VIP':
      return FontAwesomeIcons.crown;
    case 'ELECTRIC':
      return FontAwesomeIcons.bolt;
    case 'DISABLED':
      return FontAwesomeIcons.wheelchair;
    case 'MOTORCYCLE':
      return FontAwesomeIcons.motorcycle;
    default:
      return FontAwesomeIcons.car;
  }
}
