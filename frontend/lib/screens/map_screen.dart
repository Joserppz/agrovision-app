// screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgroColors.cream,
      appBar: AppBar(
        title: const Text('Mapa de enfermedades'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: AgroColors.border, size: 56),
            SizedBox(height: 12),
            Text('Mapa — próximamente',
                style: TextStyle(
                    fontFamily: AgroText.fontBody,
                    color: AgroColors.textHint)),
            SizedBox(height: 6),
            Text('flutter_map + heatmap + GPS',
                style: TextStyle(
                    fontFamily: AgroText.fontBody,
                    fontSize: 12,
                    color: AgroColors.textHint)),
          ],
        ),
      ),
    );
  }
}