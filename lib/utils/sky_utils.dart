import 'package:flutter/material.dart';
import 'dart:math' as math;

class SkyUtils {
  // Colors for each celestial type 
  static Color colorForType(String type) {
    switch (type) {
      case 'star': return const Color(0xFFCDA882);    
      case 'planet': return const Color(0xFF4FC3F7); 
      case 'moon': return const Color(0xFFE8E8D0);   
      case 'sun': return const Color(0xFFD46464);
      case 'constellation': return const Color(0xFFCDA882); 
      case 'dwarf_planet': return const Color(0xFFE18E3A); 
      default: return Colors.white.withValues(alpha:0.7);
    }
  }

  // Size based on type and magnitude (for stars)
  static double sizeForType(String type, {required double magnitude}) {
    switch (type) {
      case 'star':
        // Magnitude 1 → size 5, magnitude 5 → size 1.5
        // Clamp so nothing is too big or too small
        return (6.0 - magnitude).clamp(2.5, 6.0);
      case 'planet': 
        return 10;
      case 'moon': return 12;
      case 'sun': return 18;
      case 'dwarf_planet': return 8;
      default: return 3;
    }
  }

  // Type determination from ID
  static String typeFor(String id) {
    switch (id.toLowerCase()) {
      case 'sun':   return 'sun';
      case 'moon':  return 'moon';
      case 'pluto': return 'dwarf_planet';
      default:      return 'planet';
    }
  }

  // Path for drawing a star shape
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

  static const Map<String, String> constellationNames = {
    'ori': 'Orion',
    'uma': 'Ursa Major',
    'cas': 'Cassiopeia',
    'leo': 'Leo',
    'cyg': 'Cygnus',
    'gem': 'Gemini',
    'lib': 'Libra',
    'aql': 'Aquila',
    'aqr': 'Aquarius',
    'cet': 'Cetus',
    'her': 'Hercules',
    'lyr': 'Lyra',
    'dra': 'Draco',
    'mon': 'Monoceros',
    'cnc': 'Cancer',
    'and': 'Andromeda',
    'peg': 'Pegasus',
    'boo': 'Boötes',
    'vir': 'Virgo',
    'hya': 'Hydra',
    'lep': 'Lepus'
  };

  static Map<String, String> planetImageAssets = {
    'sun':     'assets/images/sun.png',
    'moon':    'assets/images/moon.png',
    'mercury': 'assets/images/mercury.png',
    'venus':   'assets/images/venus.png',
    'mars':    'assets/images/mars.png',
    'jupiter': 'assets/images/jupiter.png',
    'saturn':  'assets/images/saturn.png',
    'uranus':  'assets/images/uranus.png',
    'neptune': 'assets/images/neptune.png',
    'pluto':   'assets/images/pluto.png',
  };

  // Descriptions for each constellation
  static String constellationDescriptionFor(String id) {
    const descriptions = {
      'ori': 'Orion the Hunter is one of the most recognizable constellations in the night sky. It contains two of the brightest stars — red supergiant Betelgeuse and blue supergiant Rigel.',
      'uma': 'Ursa Major the Great Bear contains the famous Big Dipper asterism. Its two pointer stars guide navigators to Polaris, the North Star.',
      'cas': 'Cassiopeia the Queen is shaped like a W or M in the sky. It sits opposite the Big Dipper and is visible year-round from northern latitudes.',
      'leo': 'Leo the Lion is a zodiac constellation representing the Nemean Lion of Greek mythology. Its brightest star Regulus sits almost exactly on the ecliptic.',
      'cyg': 'Cygnus the Swan flies along the Milky Way. Its brightest star Deneb forms one corner of the famous Summer Triangle.',
      'gem': 'Gemini the Twins represents Castor and Pollux from Greek mythology. It is a zodiac constellation best seen in winter skies.',
      'lib': 'Libra the Scales is the only zodiac constellation representing an inanimate object. It was once considered the claws of neighboring Scorpius.',
      'aql': 'Aquila the Eagle carries the thunderbolts of Zeus in Greek mythology. Its brightest star Altair is one of the closest stars visible to the naked eye.',
      'aqr': 'Aquarius the Water Bearer is one of the oldest constellations, dating back to ancient Babylon. It sits in a region of the sky called the Sea.',
      'cet': 'Cetus the Sea Monster is one of the largest constellations in the sky. It is home to Mira, the most famous variable star, and Tau Ceti — a nearby Sun-like star.',
      'her': 'Hercules the Hero is the fifth largest constellation. It contains the Great Hercules Cluster — one of the brightest globular clusters visible to the naked eye.',
      'lyr': 'Lyra the Lyre is a small but prominent constellation in the northern hemisphere. It contains the bright star Vega, one of the brightest stars in the night sky.',
      'dra': 'Draco the Dragon winds around the north celestial pole. It contains Thuban, which was the pole star around 2700 BC, and the Cat\'s Eye Nebula.',
      'mon': 'Monoceros the Unicorn is a faint constellation located on the celestial equator. It contains the Rosette Nebula and the Christmas Tree Cluster.',
      'cnc': 'Cancer the Crab is a zodiac constellation. It is visible in the northern hemisphere during summer months.',
      'and': 'Andromeda is a large spiral galaxy visible in the northern hemisphere. It is the closest major galaxy to the Milky Way.',
      'peg': 'Pegasus the Winged Horse is a large constellation in the northern sky. It contains the Great Square asterism and the globular cluster M15.',
      'boo': 'Boötes the Herdsman is a large constellation in the northern sky. It contains the bright star Arcturus, one of the brightest stars in the night sky.',
      'vir': 'Virgo the Virgin is a large constellation in the northern sky. It contains the bright star Spica, one of the brightest stars in the night sky.',
      'hya': 'Hydra the Water Snake is the largest constellation in the sky. It contains the bright star Alphard and the open cluster M48.',
      'lep': 'Lepus the Hare is a small constellation located just south of Orion. It contains the bright star Arneb and the globular cluster M79.',
    };
    return descriptions[id.toLowerCase()] ?? 'A constellation in the night sky.';
  }

  // Descriptions for each planets and major objects
  static String descriptionFor(String id) {
    const descriptions = {
      // ☀️ Solar System
      'sun':      'The star at the center of our Solar System. About 109 Earths would fit across its diameter. Its surface temperature is around 5,500°C.',
      'moon':     'Earth\'s only natural satellite, about 384,000 km away. The same side always faces us. It causes our ocean tides.',
      'mercury':  'The smallest planet and closest to the Sun. A year lasts only 88 days, but a single day lasts 59 Earth days.',
      'venus':    'The hottest planet at 465°C — even hotter than Mercury. It spins backwards compared to most planets.',
      'mars':     'The Red Planet. Home to Olympus Mons, the largest volcano in the Solar System — three times the height of Everest.',
      'jupiter':  'The largest planet — over 1,300 Earths could fit inside it. Its Great Red Spot is a storm that has raged for over 350 years.',
      'saturn':   'Its stunning rings are made of ice and rock, stretching 282,000 km wide but only about 1 km thick.',
      'uranus':   'An ice giant that rotates on its side at a 98° tilt. It has 13 known rings and 28 moons.',
      'neptune':  'The farthest planet, 30 times farther from the Sun than Earth. Its winds reach 2,100 km/h — the fastest in the Solar System.',
      'pluto':    'A dwarf planet in the Kuiper Belt. Despite being smaller than our Moon, it has five known moons of its own.',
    };

    return descriptions[id.toLowerCase()] ?? '';
  }
}
// utils/sky_utils.dart  
// - Contains LOGIC (how to color, size, describe objects)
// - Pure functions, no state
// - Reusable by painter, API, repository
