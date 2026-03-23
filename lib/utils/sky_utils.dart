import 'package:flutter/material.dart';

class SkyUtils {
  // 🎨 Colors for each celestial type
  static Color colorForType(String type) {
    switch (type) {
      case 'star': return const Color(0xFFFFD700);     // Gold
      case 'planet': return const Color(0xFF4FC3F7);  // Cyan
      case 'moon': return const Color(0xFFE8E8D0);    // Cream
      case 'sun': return Colors.amber;
      case 'constellation': return const Color(0xFF5C6BC0); // Indigo
      case 'background_star': return Colors.white.withValues(alpha:0.6);
      case 'dwarf_planet': return const Color(0xFFCDA882);  // Brown
      default: return Colors.white;
    }
  }

  // 📏 Sizes for each celestial type
  static double sizeForType(String type) {
    switch (type) {
      case 'star': return 10;
      case 'planet': return 6;
      case 'moon': return 8;
      case 'sun': return 15;
      case 'constellation': return 4;
      case 'background_star': return 1;
      case 'dwarf_planet': return 3;
      default: return 2;
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
}

// utils/sky_utils.dart  ← ✅ PERFECT
// - Contains LOGIC (how to color, size, describe objects)
// - Pure functions, no state
// - Reusable by painter, API, repository