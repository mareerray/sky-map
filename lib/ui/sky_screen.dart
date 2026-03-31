import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/bloc/sky_event.dart';
import '../bloc/sky_bloc.dart';
import '../bloc/sky_state.dart';
import '../models/celestial_object.dart';
import '../utils/sky_utils.dart';
import 'sky_painter.dart';
import 'package:google_fonts/google_fonts.dart';

class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  CelestialObject? _selectedObject;
  String? imageAsset;


  @override
  void initState() {
    super.initState();
    // 🆕 TRIGGER DATA LOADING!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkyBloc>().add(LoadSkyObjects());
    });
  }

  void _onTap(TapUpDetails details, List<CelestialObject> objects, Size size, double phoneAzimuth, double phoneAltitude) {
    final tapPos = details.localPosition;

    CelestialObject? nearest;
    double nearestDistance = double.infinity;

    for (final obj in objects) {

      // Only planets and constellations are tappable — skip stars
      if (obj.type == 'star') continue;

      final screenPos = SkyPainter.toScreen(obj.azimuth, obj.altitude, size, phoneAzimuth, phoneAltitude);

      if (screenPos == null) continue;

      // 🆕 Different tap radius for constellations vs stars
      final tapRadius = obj.type == 'constellation' ? 120.0 : 30.0;
      final dist = (screenPos - tapPos).distance;

      if (dist < tapRadius && dist < nearestDistance) {
        nearestDistance = dist;
        nearest = obj;
      }
    }

    const double maxTapRadius = 40.0; // max distance in pixels


    setState(() {
      if (nearest != null && nearestDistance <= maxTapRadius) {
        _selectedObject = nearest; // close enough → select it
        imageAsset = SkyUtils.planetImageAssets[_selectedObject!.id];
      } else {
        _selectedObject = null;    // too far → deselect (tap empty sky)
        imageAsset = null;
      }
    });  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60), 
        child: BlocBuilder<SkyBloc, SkyState>(
          builder: (context, state) {
            return AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(left: 16), 
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sky Map',
                        style: GoogleFonts.notable(
                          color: Color(0xFF4FC3F7),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Sensors (only show when loaded)
                  if (state is SkyLoaded)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Az: ${state.phoneAzimuth.toStringAsFixed(0)}°',
                            style: GoogleFonts.poppins(color: Color(0xFF4FC3F7), fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Alt: ${state.phoneAltitude.toStringAsFixed(0)}°',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              centerTitle: false,
            );
          },
        ),
      ),      
      body: BlocBuilder<SkyBloc, SkyState>(
        builder: (context, state) {

          if (state is SkyLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state is SkyLoaded) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: [

                    // Sky canvas with tap detection
                    GestureDetector(
                      onTapUp: (details) =>
                          _onTap(details, state.celestialObjects, size, state.phoneAzimuth, state.phoneAltitude),
                      child: CustomPaint(
                        painter: SkyPainter(
                          objects: state.celestialObjects,
                          selectedObject: _selectedObject,
                          constellationLines: state.constellationLines,
                          phoneAzimuth: state.phoneAzimuth,
                          phoneAltitude: state.phoneAltitude,
                          planetImages: state.planetImages, 
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // Info card — only visible when an object is tapped
                    if (_selectedObject != null)
                      Positioned(
                        bottom: 45,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (imageAsset != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),  
                                    topRight: Radius.circular(12),
                                  ),
                                  child: SizedBox(
                                    height: 100,                    
                                    width: double.infinity,         
                                    child: Image.asset(
                                      imageAsset!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                                else if (_selectedObject!.type == 'constellation')
                                  Container(
                                height: 60,
                                alignment: Alignment.centerLeft,
                                child: const Icon(
                                  Icons.auto_awesome,           // ✨ star sparkle icon
                                  color: Color(0xFFCDA882),     // same gold as your labels
                                  size: 36,
                                ),
                              ),
                              Text(
                                _selectedObject!.name,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedObject!.type == 'constellation'
                                  ? SkyUtils.constellationDescriptionFor(_selectedObject!.id.replaceAll('constellation_', '').toLowerCase())
                                  : _selectedObject!.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          }

          if (state is SkyError) {
            return Center(
              child: Text(state.message,
                  style: const TextStyle(color: Colors.red)),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// This is where we'll finally see something on screen. 
// This screen has one job — listen to the BLoC and show the right thing based on the state:

// State	    | What the screen shows
// SkyLoading	| A loading spinner
// SkyLoaded	| The sky map (black canvas with dots)
// SkyError	  | An error message

// Key Concept — BlocBuilder
// BlocBuilder is a widget that rebuilds itself every time the BLoC emits a new state. 
// Think of it like a screen that refreshes automatically when new information arrives.