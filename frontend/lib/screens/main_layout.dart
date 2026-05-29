// lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'history_screen.dart';

class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController navCtrl = Get.put(NavigationController());

  final List<Widget> pages = [
    const HomeScreen(),
    const MapScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => pages[navCtrl.currentIndex.value]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFECE8DF), width: 1)),
        ),
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 'Inicio', 0),
            _buildScanButton(),
            _buildNavItem(Icons.map_rounded, 'Mapa', 1),
            _buildNavItem(Icons.list_alt_rounded, 'Historial', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Obx(() {
      bool isActive = navCtrl.currentIndex.value == index;
      return GestureDetector(
        onTap: () => navCtrl.changePage(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: isActive ? const Color(0xFF2D5A27) : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF2D5A27) : Colors.grey.shade400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () => Get.toNamed('/camera'),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2D5A27),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDFBF7), width: 3),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2D5A27).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
              SizedBox(height: 2),
              Text('SCAN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}