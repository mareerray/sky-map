import 'package:flutter/material.dart';
import 'dart:math' as math;

class SkyUtils {
  // 🎨 Colors for each celestial type
  static Color colorForType(String type) {
    switch (type) {
      case 'star': return const Color(0xFFCDA882);     // Gold
      case 'planet': return const Color(0xFF4FC3F7);  // Cyan
      case 'moon': return const Color(0xFFE8E8D0);    // Cream
      case 'sun': return const Color(0xFFD46464);
      case 'constellation': return const Color(0xFFCDA882); 
      case 'dwarf_planet': return const Color(0xFFE18E3A);  // Brown
      default: return Colors.white.withValues(alpha:0.7);
    }
  }

  // 📏 Sizes for each celestial type
  static double sizeForType(String type, {required double magnitude}) {
    switch (type) {
      case 'star':
        // Magnitude 1 → size 5, magnitude 5 → size 1.5
        // Clamp so nothing is too big or too small
        return (6.0 - magnitude).clamp(2.5, 6.0);
      case 'planet': return 10;
      case 'moon': return 14;
      case 'sun': return 18;
      case 'dwarf_planet': return 8;
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
  };

  // Add this constant somewhere accessible, e.g. in sky_utils.dart
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
    };
    return descriptions[id.toLowerCase()] ?? 'A constellation in the night sky.';
  }

  // 📝 Descriptions for each body
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
      // // 🔵 ORION
      // 'betelgeuse':   'A red supergiant marking Orion\'s right shoulder. Will one day explode as a supernova.',
      // 'meissa':       'A hot blue star marking the head of Orion the Hunter.',
      // 'bellatrix':    'A blue giant marking Orion\'s left shoulder. Known as the "Female Warrior".',
      // 'mintaka':      'The westernmost star in Orion\'s Belt, about 900 light-years away.',
      // 'alnilam':      'The middle star in Orion\'s Belt. One of the most luminous stars known.',
      // 'alnitak':      'The eastern star in Orion\'s Belt. A triple star system.',
      // 'rigel':        'A brilliant blue supergiant marking Orion\'s left foot. The brightest star in Orion.',
      // 'saiph':        'A blue supergiant marking Orion\'s right foot, similar in size to Rigel.',
      // 'tabit':        'A yellow-white star in the shield of Orion, similar to our Sun.',
      // 'mu orionis':   'A multiple star system in the arm of Orion.',
      // 'xi orionis':   'A yellow giant in the outer regions of Orion.',
      // 'nu orionis':   'A blue-white star near the boundary of Orion.',
      // 'chi orionis':  'A faint star in the northern part of Orion.',

      // // 🦢 CYGNUS
      // 'sadr':         'A yellow supergiant marking the chest of Cygnus the Swan.',
      // 'alpha cygni':  'Also called Deneb. A white supergiant — one of the most luminous stars in the galaxy.',
      // 'deneb':        'A white supergiant in Cygnus. Part of the Summer Triangle. Over 100,000 times more luminous than the Sun.',
      // 'delta cygni':  'A double star in the neck of Cygnus, about 165 light-years away.',
      // 'iota cygni':   'A blue-white star in the northern wing of Cygnus.',
      // 'kappa cygni':  'An orange giant near the tip of Cygnus\'s northern wing.',
      // 'eta cygni':    'An orange giant star in the body of Cygnus.',
      // 'albireo b':      'A famous double star — one gold, one blue — marking the beak of Cygnus.',
      // 'gienah':       'An orange giant marking the southern wing of Cygnus.',
      // 'zeta cygni':   'A yellow giant star in the southern wing of Cygnus.',
      // 'mu cygni':     'A binary star system at the tip of Cygnus\'s southern wing.',

      // // 🐻 URSA MAJOR
      // 'dubhe':                  'One of the two "pointer stars" that lead to the North Star Polaris.',
      // 'merak':                  'The second pointer star in the Big Dipper, guiding toward Polaris.',
      // 'phecda':                 'A white star at the bottom of the Big Dipper\'s bowl.',
      // 'megrez':                 'The faintest star in the Big Dipper, connecting the bowl to the handle.',
      // 'alioth':                 'The brightest star in Ursa Major and the handle of the Big Dipper.',
      // 'mizar':                  'The middle handle star of the Big Dipper. Has a famous companion star, Alcor.',
      // 'alkaid':                 'The tip of the Big Dipper\'s handle, about 100 light-years away.',
      // 'chi ursae majoris':      'An orange giant in the hind leg of the Great Bear.',
      // 'psi ursae majoris':      'A red giant star in the southern body of Ursa Major.',
      // 'tania borealis':         'The northern of the two "Tania" stars in the hind paws of the Great Bear.',
      // 'tania australis':        'The southern of the two "Tania" stars. A red giant star.',
      // '23 ursae majoris':       'A yellow giant star in the head of Ursa Major.',
      // 'muscida':                'An orange giant marking the snout of the Great Bear.',
      // 'upsilon ursae majoris':  'A yellow-white subgiant in the neck of Ursa Major.',
      // 'phi ursae majoris':      'A faint star in the body of Ursa Major.',
      // '26 ursae majoris':       'A yellow giant in the chest region of Ursa Major.',
      // 'theta ursae majoris':    'An orange subgiant in the Great Bear, about 44 light-years away.',
      // 'kappa ursae majoris':    'A binary star system in the forepaw of the Great Bear.',
      // 'talitha':                'A double star marking the front foot of Ursa Major.',

      // // 👑 CASSIOPEIA
      // 'segin':    'A blue giant at one end of the W-shape of Cassiopeia.',
      // 'ruchbah':  'A white star in Cassiopeia known for its slow pulsations.',
      // 'cih':      'The central star of Cassiopeia\'s W, also called Gamma Cassiopeiae.',
      // 'schedar':  'The brightest star in Cassiopeia. A giant orange star.',
      // 'caph':     'A yellow-white star at the other end of the W in Cassiopeia.',

      // // 🦁 LEO
      // 'denebola':             'A white star marking the tail of Leo the Lion.',
      // 'zosma':                'A white star on the hip of Leo, about 58 light-years away.',
      // 'chertan':              'A white star on the haunch of Leo the Lion.',
      // 'regulus':              'The brightest star in Leo. Marks the heart of the Lion. Spins so fast it bulges at its equator.',
      // 'algieba':              'A beautiful double star system forming the mane of Leo.',
      // 'eta leonis':           'A white supergiant in the neck of Leo.',
      // 'adhafera':             'A giant star in the head of Leo, part of the curved "sickle" shape.',
      // 'rasalas':              'An orange giant marking the top of the Lion\'s head.',
      // 'ras elased australis': 'The southernmost of the two bright stars at the tip of Leo\'s sickle.',

      // // 👯 GEMINI
      // 'pollux':               'The brightest star in Gemini. An orange giant with a confirmed planet orbiting it.',
      // 'castor b':               'Appears as one star but is actually a system of six stars.',
      // 'upsilon geminorum':    'An orange giant in the body of Gemini.',
      // 'kappa geminorum':      'An orange giant star in the southern foot of Gemini.',
      // 'iota geminorum':       'A yellow giant in the arm of one of the Gemini twins.',
      // 'wasat':                'A binary star system in the waist of Gemini.',
      // 'lambda geminorum':     'A white star in the body of Gemini.',
      // 'mekbuda':              'A pulsating yellow supergiant — its size changes over a 10-day cycle.',
      // 'alhena':               'A brilliant white star marking the left foot of Gemini.',
      // 'alzirr':               'A yellow-white subgiant near the foot of the southern twin.',
      // 'tau geminorum':        'An orange giant in the body of Gemini.',
      // 'theta geminorum':      'A white giant in the body of Gemini.',
      // 'mebsuta':              'A yellow supergiant in the outstretched arm of Gemini.',
      // 'nu geminorum':         'A binary star system in the arm of Gemini.',
      // 'tejat':                'An orange-red giant marking the foot of the northern Gemini twin.',
      // 'propus':               'A variable red giant star at the foot of Gemini.',
      // '1 geminorum':          'A faint binary star at the edge of the Gemini constellation.',

      //       // ⚖️ LIBRA
      // 'zubeneschamali':   'The brightest star in Libra. A blue-white giant — one of the few stars with a visibly greenish hue.',
      // 'zubenelgenubi':    'A double star marking the southern claw of Libra. Its name means "the southern claw" in Arabic.',
      // 'brachium':         'An orange giant in Libra, formerly considered part of Scorpius.',
      // 'zubenelakrab':     'A faint star in Libra, whose name means "the scorpion\'s claw" in Arabic.',
      // 'tau librae':       'A blue-white star near the northern edge of Libra.',
      // 'upsilon librae':   'An orange giant in the eastern part of Libra.',

      // // 🦅 AQUILA
      // 'altair':           'One of the closest stars visible to the naked eye, just 17 light-years away. Part of the Summer Triangle.',
      // 'tarazed':          'A bright orange giant in Aquila, forming the shoulder of the Eagle.',
      // 'okab':             'A white star marking the tail of Aquila the Eagle.',
      // 'theta aquilae':    'A blue-white giant in the body of Aquila.',
      // 'eta aquilae':      'A pulsating yellow supergiant — one of the brightest Cepheid variable stars.',
      // 'delta aquilae':    'A yellow-white subgiant in the wing of Aquila.',
      // 'lambda aquilae':   'A blue-white star marking the southern wing tip of the Eagle.',
      // 'iota aquilae':     'A blue giant in the body of Aquila the Eagle.',
      // 'zeta aquilae':     'A white star in the neck of Aquila, about 83 light-years away.',

      // // 💧 AQUARIUS
      // 'sadalsuud':        'The brightest star in Aquarius. Its name means "luckiest of the lucky" in Arabic.',
      // 'sadalmelik':       'A yellow supergiant marking the right shoulder of the Water Bearer.',
      // 'skat':             'A white star in the lower body of Aquarius, about 160 light-years away.',
      // 'albali':           'A white star in Aquarius whose name means "the swallower" in Arabic.',
      // 'ancha':            'A yellow subgiant in the hip of Aquarius the Water Bearer.',
      // 'eta aquarii':      'A blue-white star in the water stream flowing from Aquarius.',
      // 'sadachbia':        'A blue-white giant marking the lucky stars of the tents in Arabic tradition.',
      // 'zeta aquarii':     'A binary star system at the center of the water jar in Aquarius.',

      // // 🐋 CETUS
      // 'menkar':           'A red giant marking the nose of Cetus the Sea Monster.',
      // 'diphda':           'The brightest star in Cetus. An orange giant also called Deneb Kaitos.',
      // 'mira':             'The most famous variable star — its brightness changes dramatically over 332 days.',
      // 'baten kaitos':     'An orange giant in the belly of Cetus, about 260 light-years away.',
      // 'kaffaljidhma':     'A binary star system marking the head of Cetus the Sea Monster.',
      // 'tau ceti':         'One of the closest Sun-like stars, just 12 light-years away. A top target in the search for life.',
      // 'deneb algenubi':   'An orange giant in the tail of Cetus, whose name means "southern tail" in Arabic.',
      // 'theta ceti':       'A yellow giant in the body of Cetus the Sea Monster.',
      // 'eta ceti':         'An orange giant star in the neck region of Cetus.',
      // 'nu ceti':          'A yellow giant in the head region of Cetus.',

      // // 💪 HERCULES
      // 'kornephoros':      'The brightest star in Hercules. A yellow giant marking the right shoulder of the Hero.',
      // 'zeta herculis':    'A yellow subgiant forming the right hip of Hercules. Has a planet-like companion.',
      // 'sarin':            'A white star marking the left shoulder of Hercules.',
      // 'marsic':           'An orange giant in the bent arm of Hercules the Hero.',
      // 'mu herculis':      'A yellow star similar to the Sun, just 27 light-years away.',
      // 'omicron herculis': 'A blue-white giant in the body of Hercules.',
      // 'xi herculis':      'A yellow giant in the lower body of Hercules.',
      // 'iota herculis':    'A blue-white star in the foot of Hercules.',
      // 'theta herculis':   'An orange giant marking the knee of Hercules.',
      // 'eta herculis':     'A yellow giant star in the torso of Hercules the Hero.',
      // 'pi herculis':      'An orange giant in the shoulder of Hercules, about 370 light-years away.',
    };

    return descriptions[id.toLowerCase()] ?? '';
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