import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants.dart';
import '../controllers/connectivity_controller.dart';
import '../widgets/offline_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => connectivity.isOnline.value
                ? const SizedBox.shrink()
                : const OfflineBanner()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStats(),
                    const SizedBox(height: 20),
                    _buildDiseaseList(),
                    const SizedBox(height: 24),
                    _buildScanButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(painter: _LogoPainter()),
        ),
        const SizedBox(height: 12),
        Text('AGROVISION', style: Get.textTheme.displayMedium),
        const SizedBox(height: 4),
        Text(
          'INTI AGRO · BOLIVIA',
          style: Get.textTheme.labelSmall
              ?.copyWith(letterSpacing: 2.5, color: AgroColors.brown),
        ),
        const SizedBox(height: 8),
        Text(
          'Diagnóstico inteligente de cultivos\ncon Inteligencia Artificial',
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium
              ?.copyWith(color: AgroColors.brown, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(children: [
      _StatCard(value: '4',   label: 'Enfermedades'),
      const SizedBox(width: 8),
      _StatCard(value: '97%', label: 'Precisión'),
      const SizedBox(width: 8),
      _StatCard(value: '<1s', label: 'Respuesta'),
    ]);
  }

  Widget _buildDiseaseList() {
    final diseases = [
      ('Tizón Tardío',  'Late Blight',  AgroColors.red),
      ('Mancha Foliar', 'Septoria',     AgroColors.orange),
      ('Arañuela Roja', 'Spider Mites', AgroColors.purple),
      ('Planta Sana ✓', 'Healthy',      AgroColors.healthy),
    ];
    return Column(
      children: diseases.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AgroColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AgroColors.border),
          ),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: d.$3, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(d.$1,
              style: const TextStyle(
                fontFamily: AgroText.fontBody, fontSize: 13,
                fontWeight: FontWeight.w600, color: AgroColors.green))),
            Text(d.$2,
              style: const TextStyle(
                fontFamily: AgroText.fontBody, fontSize: 11,
                fontWeight: FontWeight.w600, color: AgroColors.yellow)),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Get.toNamed(AgroRoutes.camera),
        icon: const Icon(Icons.camera_alt_outlined, size: 20),
        label: const Text('ESCANEAR CULTIVO'),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AgroColors.surface,
        border: Border(top: BorderSide(color: AgroColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) Get.toNamed(AgroRoutes.map);
          if (i == 2) Get.toNamed(AgroRoutes.history);
          if (i == 3) Get.toNamed(AgroRoutes.forum);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),    label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined),     label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined),   label: 'Foro'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AgroColors.greenFaint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(
          fontFamily: AgroText.fontDisplay, fontSize: 20,
          fontWeight: FontWeight.w700, color: AgroColors.green)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontFamily: AgroText.fontBody, fontSize: 9,
          fontWeight: FontWeight.w500, color: AgroColors.brown,
          letterSpacing: 0.8)),
      ]),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2.2;

    // Sol
    canvas.drawCircle(Offset(cx, cy), 11, Paint()..color = AgroColors.yellow);
    final rayPaint = Paint()
      ..color = AgroColors.yellow
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + 16 * math.cos(a), cy + 16 * math.sin(a)),
        Offset(cx + 22 * math.cos(a), cy + 22 * math.sin(a)),
        rayPaint,
      );
    }

    // Tallo
    canvas.drawLine(Offset(cx, cy + 14), Offset(cx, size.height - 4),
      Paint()..color = AgroColors.green..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);

    // Hoja
    final leaf = Path()
      ..moveTo(cx, cy + 28)
      ..quadraticBezierTo(cx - 12, cy + 20, cx - 8, cy + 14)
      ..quadraticBezierTo(cx - 4, cy + 20, cx, cy + 28);
    canvas.drawPath(leaf, Paint()..color = AgroColors.green.withOpacity(0.8));

    // Pétalos
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 8 * math.cos(a), cy + 8 * math.sin(a)),
          width: 10, height: 14),
        Paint()..color = i.isEven
            ? const Color(0xFFE74C3C)
            : const Color(0xFFC0392B),
      );
    }

    // Centro rosa
    canvas.drawCircle(
        Offset(cx, cy), 5, Paint()..color = const Color(0xFF922B21));
  }

  @override
  bool shouldRepaint(_) => false;
}