// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            _buildBrandHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildDiseaseList(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed('/camera'),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('ESCANEAR CULTIVO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A27),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // Logo Simulado (Rosa y Sol)
        Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.wb_sunny, color: Color(0xFFFBB03B), size: 70),
            Positioned(bottom: 0, child: Icon(Icons.local_florist, color: const Color(0xFFC0392B).withOpacity(0.9), size: 45)),
          ],
        ),
        const SizedBox(height: 12),
        Text('AGROVISION', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF2D5A27), letterSpacing: 1)),
        const Text('INTI AGRO · BOLIVIA', style: TextStyle(fontSize: 11, color: Color(0xFF6B4423), letterSpacing: 2.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text('Diagnóstico inteligente de cultivos\ncon Inteligencia Artificial', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF6B4423), fontWeight: FontWeight.w300)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statPill('4', 'Enfermedades'),
        const SizedBox(width: 8),
        _statPill('97%', 'Precisión'),
        const SizedBox(width: 8),
        _statPill('<1s', 'Respuesta'),
      ],
    );
  }

  Widget _statPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFEEF4EC), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D5A27))),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Color(0xFF6B4423), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseList() {
    return Column(
      children: [
        _diseaseItem(const Color(0xFFC0392B), 'Tizón Tardío', 'Late Blight'),
        _diseaseItem(const Color(0xFFE67E22), 'Mancha Foliar', 'Septoria'),
        _diseaseItem(const Color(0xFF8E44AD), 'Arañuela Roja', 'Spider Mites'),
        _diseaseItem(const Color(0xFF27AE60), 'Planta Sana', 'Healthy ✓'),
      ],
    );
  }

  Widget _diseaseItem(Color color, String name, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFECE8DF))),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27)))),
          Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFBB03B))),
        ],
      ),
    );
  }
}