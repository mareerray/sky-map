import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bloc/sky_bloc.dart';
import 'bloc/sky_event.dart';
import 'data/celestial_repository.dart';
import 'ui/sky_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create the BLoC and immediately send the load event
      create: (context) => SkyBloc(CelestialRepository())
        ..add(LoadSkyObjects()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sky Map',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF4FC3F7), // ← global primary color
          ),
          textTheme: TextTheme(
            bodyLarge: GoogleFonts.poppins(
              color: Color(0xFF4FC3F7),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            bodyMedium: GoogleFonts.poppins(
              color: Color(0xFF4FC3F7),
              fontSize: 14,
            ),
          ),
        ), // Dark theme fits a night sky app 🌙
        home: const WelcomeWrapper(),
      ),
    );
  }
}

class WelcomeWrapper extends StatefulWidget {
  const WelcomeWrapper({super.key});

  @override
  State<WelcomeWrapper> createState() => _WelcomeWrapperState();
}

class _WelcomeWrapperState extends State<WelcomeWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // allow swipe to dismiss
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(20),
        title: Text(
          '🌌 Welcome to \n Sky Map',
          style: GoogleFonts.notable(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4FC3F7),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4FC3F7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Tilt your phone to look around\n'
                    '• Tap planets, Sun, Moon, or constellations to see details\n'
                    '• Red compass shows North\n'
                    '• Objects fade below horizon',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data sources:\n'
                      '• Astronomy APIs \n'
                      '• HYG Database v3.2 (stars) ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4FC3F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF4FC3F7)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Start Exploring',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }  

  @override
  Widget build(BuildContext context) {
    return const SkyScreen();
  }
}


// This file is the root widget — think of it as the restaurant manager who:
// - Hires the chef (SkyBloc)
// - Makes sure the chef is available to every room in the restaurant (every screen)
// - Sends the first order (LoadSkyObjects) as soon as the restaurant opens

// Note:

// BlocProvider — this is a special Flutter widget that creates the BLoC and makes it accessible 
// to all child widgets below it. Think of it as putting the chef in charge of the whole restaurant.

// ..add(LoadSkyObjects()) — the .. is called a cascade operator. 
// It means "on the same object, also do this." 
// So it creates SkyBloc AND immediately sends the first event in one line.