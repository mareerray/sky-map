import 'package:flutter/material.dart';
import 'dart:math' as math;

class SkyUtils {
  // 🎨 Colors for each celestial type
  static Color colorForType(String type) {
    switch (type) {
      case 'star': return const Color(0xFFCDA882);     // Gold
      case 'bright_star': return const Color(0xFFCDA882);     // Gold
      case 'planet': return const Color(0xFF4FC3F7);  // Cyan
      case 'moon': return const Color(0xFFE8E8D0);    // Cream
      case 'sun': return const Color(0xFFD46464);
      case 'constellation': return const Color(0xFFCDA882); // Indigo
      // case 'constellation': return const Color(0xFF5C6BC0); // Indigo
      case 'background_star': return Colors.white.withValues(alpha:0.6);
      case 'dwarf_planet': return const Color(0xFFE18E3A);  // Brown
      default: return Colors.white.withValues(alpha:0.7);
    }
  }

  // 📏 Sizes for each celestial type
  static double sizeForType(String type, {required double magnitude}) {
    switch (type) {
      case 'star': return 7;
      case 'bright_star': return 7;
      case 'planet': return 10;
      case 'moon': return 14;
      case 'sun': return 18;
      case 'dwarf_planet': return 8;
      case 'bg_star':     return 3; 
      default: return 3;
    }
  }

  // 🔤 Type determination from ID
  static String typeFor(String id) {
    switch (id.toLowerCase()) {
      case 'sun':   return 'sun';
      case 'moon':  return 'moon';
      case 'pluto': return 'dwarf_planet';
      default:      return 'planet';
    }
  }

  // 📝 Descriptions for each body
  static String descriptionFor(String id) {
    const descriptions = {
      'sun':     'The star at the center of our Solar System.',
      'moon':    'Earth\'s only natural satellite.',
      'mercury': 'The smallest planet and closest to the Sun.',
      'venus':   'The hottest planet. Brightest object in the night sky after the Moon.',
      'mars':    'The Red Planet. Has the largest volcano in the Solar System.',
      'jupiter': 'The largest planet. Has a giant storm called the Great Red Spot.',
      'saturn':  'Known for its stunning ring system made of ice and rock.',
      'uranus':  'An ice giant that rotates on its side.',
      'neptune': 'The farthest planet. Has the strongest winds in the Solar System.',
      'pluto':   'A dwarf planet in the Kuiper Belt.',
    };
    return descriptions[id.toLowerCase()] ?? '';
  }

    static Path starPath(Offset center, double radius, {int points = 5}) {
    final path = Path();
    final outer = radius;
    final inner = radius * 0.38;  // Pointy star
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i % 2 == 0 ? outer : inner;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {  
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}

// utils/sky_utils.dart  ← ✅ PERFECT
// - Contains LOGIC (how to color, size, describe objects)
// - Pure functions, no state
// - Reusable by painter, API, repository

// 📍 GPS: lat=60.1187943, lon=19.9461192
// 🌟 Sun (id:sun) magnitude: -26.74917
// 🌟 Moon (id:moon) magnitude: -8.96246
// 🌟 Mercury (id:mercury) magnitude: 0.78568
// 🌟 Venus (id:venus) magnitude: -3.85289
// 🌟 Mars (id:mars) magnitude: 1.18651
// 🌟 Jupiter (id:jupiter) magnitude: -2.28169
// 🌟 Saturn (id:saturn) magnitude: 0.78793
// 🌟 Uranus (id:uranus) magnitude: 5.77124
// 🌟 Neptune (id:neptune) magnitude: 7.95551
// 🌟 Pluto (id:pluto) magnitude: 14.58575