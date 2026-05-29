// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simula el tiempo de la IA (2.5 segundos) y luego va a resultados
    Future.delayed(const Duration(milliseconds: 2500), () {
      Get.offNamed('/results');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(color: const Color(0xFFE8F0E6), borderRadius: BorderRadius.circular(24)),
              child: const Center(
                child: SizedBox(
                  width: 60, height: 60,
                  child: CircularProgressIndicator(color: Color(0xFF2D5A27), strokeWidth: 4),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Consultando modelo YOLOv8', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27))),
            const SizedBox(height: 12),
            const Text('Enviando imagen al servidor FastAPI\nvía Ngrok → Supabase', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF6B4423), height: 1.5)),
          ],
        ),
      ),
    );
  }
}