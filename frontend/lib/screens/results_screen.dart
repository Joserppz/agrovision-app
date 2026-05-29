// lib/screens/results_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Banner Superior
          SizedBox(
            height: 220, width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFF1A3A15)), // Placeholder foto
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
                  ),
                ),
                Positioned(
                  top: 40, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFBB03B), borderRadius: BorderRadius.circular(12)),
                    child: const Text('87.4% confianza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                // Bounding Box simulado
                Center(
                  child: Container(
                    width: 140, height: 110,
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFBB03B), width: 2), borderRadius: BorderRadius.circular(8)),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFFFBB03B),
                        child: const Text('Tizón Tardío', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido Escroleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Enfermedad
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECE8DF))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tizón Tardío', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2D5A27))),
                                const Text('Phytophthora infestans', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF6B4423))),
                              ],
                            ),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(8)), child: const Text('CRÍTICO', style: TextStyle(color: Color(0xFFC0392B), fontSize: 10, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('SEVERIDAD ESTIMADA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B4423), letterSpacing: 1)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(value: 0.78, minHeight: 8, backgroundColor: const Color(0xFFECE8DF), color: const Color(0xFFE67E22)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tarjeta Tratamiento
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEEF4EC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFC3D8BE))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF2D5A27), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.medical_services, color: Colors.white, size: 16)),
                            const SizedBox(width: 8),
                            const Text('Tratamiento Inmediato', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D5A27))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _step(1, 'Aislar las plantas afectadas para evitar propagación por esporas en el aire.'),
                        _step(2, 'Aplicar fungicida a base de cobre (Bordeaux) cada 7 días en zonas húmedas.'),
                        _step(3, 'Reducir riego por aspersión y mejorar ventilación del cultivo.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.offAllNamed('/home'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A27), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('✓ Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.offNamed('/camera'),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2D5A27), width: 2), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('📷 Nuevo', style: TextStyle(color: Color(0xFF2D5A27), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 10, backgroundColor: const Color(0xFF2D5A27), child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF2A4025), height: 1.4))),
        ],
      ),
    );
  }
}