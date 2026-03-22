// main.dart has one job — start the app. All setup lives in app.dart.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async{
  // Load .env file before starting the app
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ← Temporary debug call
  // await AstronomyApiService().debugApiResponse();

  runApp(const App());
}
