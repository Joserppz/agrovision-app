// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/main_layout.dart';
import 'screens/camera_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/results_screen.dart';

void main() {
  runApp(const AgroVisionApp());
}

class AgroVisionApp extends StatelessWidget {
  const AgroVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AgroVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFBF7), // Cream
        primaryColor: const Color(0xFF2D5A27), // Green
        textTheme: GoogleFonts.dmSansTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDFBF7),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF2D5A27)),
          centerTitle: true,
        ),
      ),
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => MainLayout()),
        GetPage(name: '/camera', page: () => const CameraScreen()),
        GetPage(name: '/loading', page: () => const LoadingScreen()),
        GetPage(name: '/results', page: () => const ResultsScreen()),
      ],
    );
  }
}