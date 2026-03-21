import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        theme: ThemeData.dark(), // Dark theme fits a night sky app 🌙
        home: const SkyScreen(),
      ),
    );
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