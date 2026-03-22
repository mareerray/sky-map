import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sky_bloc.dart';
import '../bloc/sky_state.dart';
import '../models/celestial_object.dart';
import 'sky_painter.dart';
import 'package:google_fonts/google_fonts.dart';

class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  CelestialObject? _selectedObject;

  void _onTap(TapUpDetails details, List<CelestialObject> objects, Size size, double phoneAzimuth, double phoneAltitude) {
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    CelestialObject? nearest;
    double nearestDistance = double.infinity;

    for (final obj in objects) {
      // Must match _toScreen() in SkyPainter exactly
      final offset = SkyPainter.toScreen(
        obj.azimuth, obj.altitude, size, 
        phoneAzimuth, phoneAltitude); 
      final double distance = (offset - Offset(tapX, tapY)).distance;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = obj;
      }
    }

    setState(() {
      _selectedObject = (nearestDistance < 20) ? nearest : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,                    // no shadow
        title: Text(
          'Sky Map',
          style: GoogleFonts.notable(
            color: Color(0xFF4FC3F7),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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

                    // Sky canvas with tap detectionr
                    GestureDetector(
                      onTapUp: (details) =>
                          _onTap(details, state.celestialObjects, size, state.phoneAzimuth, state.phoneAltitude),
                      child: CustomPaint(
                        painter: SkyPainter(
                          objects: state.celestialObjects,
                          selectedObject: _selectedObject,
                          phoneAzimuth: state.phoneAzimuth,
                          phoneAltitude: state.phoneAltitude,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // Inside Stack children, after GestureDetector:
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Text(
                        'Az: ${state.phoneAzimuth.toStringAsFixed(1)}°\n'
                        'Alt: ${state.phoneAltitude.toStringAsFixed(1)}°',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            // border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedObject!.name,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedObject!.description,
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