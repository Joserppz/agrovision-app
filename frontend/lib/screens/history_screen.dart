// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Escaneos', style: TextStyle(color: Color(0xFF2D5A27), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEEF4EC), borderRadius: BorderRadius.circular(12)),
            child: const Text('7 escaneos · 5 enfermedades detectadas esta semana', style: TextStyle(fontSize: 12, color: Color(0xFF2D5A27), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _historyCard('Tizón Tardío', '📍 La Paz · Hace 2 min', '87%', const Color(0xFFC0392B), true),
          _historyCard('Septoria Foliar', '📍 El Alto · Hace 1h', '76%', const Color(0xFFE67E22), false),
          _historyCard('Planta Sana ✓', '📍 Viacha · Hace 3h', '100%', const Color(0xFF27AE60), false),
          _historyCard('Arañuela Roja', '📍 Mecapaca · Ayer', '69%', const Color(0xFF8E44AD), false),
        ],
      ),
    );
  }

  Widget _historyCard(String title, String subtitle, String conf, Color color, bool isClickable) {
    return GestureDetector(
      onTap: isClickable ? () => Get.toNamed('/results') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFECE8DF))),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: const Color(0xFF1A3A15), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Icon(Icons.eco, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: title.contains('Sana') ? const Color(0xFF27AE60) : const Color(0xFF2D5A27))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B4423))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(10)),
              child: Text(conf, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF8A5A00))),
            )
          ],
        ),
      ),
    );
  }
}