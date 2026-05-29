// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A08),
      body: Stack(
        children: [
          // Fondo simulando cámara
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(colors: [Color(0xFF1D4A15), Color(0xFF0A1A08)], radius: 1.5),
            ),
          ),
          
          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Get.back()),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF2D5A27).withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                    child: const Text('IA ACTIVA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                  const Icon(Icons.flash_on, color: Colors.white),
                ],
              ),
            ),
          ),

          // Centro: Marco de enfoque
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFBB03B).withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      // Esquinas
                      _corner(Alignment.topLeft), _corner(Alignment.topRight),
                      _corner(Alignment.bottomLeft), _corner(Alignment.bottomRight),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Centra la hoja enferma dentro del marco\nLa IA detectará automáticamente', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconBtn(Icons.photo_library),
                  GestureDetector(
                    onTap: () => Get.offNamed('/loading'),
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 4)),
                      child: Center(
                        child: Container(width: 54, height: 54, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ),
                    ),
                  ),
                  _iconBtn(Icons.cameraswitch),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight) ? const BorderSide(color: Color(0xFFFBB03B), width: 4) : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight) ? const BorderSide(color: Color(0xFFFBB03B), width: 4) : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) ? const BorderSide(color: Color(0xFFFBB03B), width: 4) : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight) ? const BorderSide(color: Color(0xFFFBB03B), width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle, border: Border.all(color: Colors.white30)),
      child: Icon(icon, color: Colors.white),
    );
  }
}