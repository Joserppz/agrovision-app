import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/offline_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final connectivity = Get.find<ConnectivityController>();

    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => connectivity.isOnline.value
                ? const SizedBox.shrink()
                : const OfflineBanner()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(controller),
                    const SizedBox(height: 24),
                    _buildMainCard(controller),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Enfermedades detectables', 'Ver todas', controller.showAllDiseasesDialog),
                    const SizedBox(height: 16),
                    _buildHorizontalDiseaseList(),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Último escaneo', 'Ver historial', () => Get.toNamed(AgroRoutes.history)),
                    const SizedBox(height: 16),
                    
                    // Renderizado condicional reactivo
                    Obx(() {
                      if (!controller.hasLastScan.value) {
                        return _buildEmptyScanCard();
                      }
                      return _buildLastScan(controller);
                    }),
                    
                    const SizedBox(height: 32),
                    const Text('Consejo del día', 
                        style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 16, fontWeight: FontWeight.bold, color: AgroColors.textPrimary)),
                    const SizedBox(height: 16),
                    _buildTipCard(controller),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(controller),
    );
  }

  Widget _buildTopHeader(HomeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(controller.greeting.value,
                style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 14, color: AgroColors.textSecondary))),
            const Text('Agricultor Visionario',
                style: TextStyle(fontFamily: AgroText.fontDisplay, fontSize: 22, fontWeight: FontWeight.bold, color: AgroColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AgroColors.yellowLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 14, color: AgroColors.orange),
                  const SizedBox(width: 6),
                  Obx(() => Text(
                      '${controller.temperature.value} · ${controller.locationName.value} · Humedad ${controller.humidity.value}',
                      style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 12, color: AgroColors.textSecondary, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: controller.showComingSoonDialog,
          child: const CircleAvatar(
            radius: 24,
            backgroundColor: AgroColors.greenFaint,
            child: Icon(Icons.person_outline, color: AgroColors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AgroColors.green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AgroColors.yellow.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('IA ACTIVA', style: TextStyle(color: AgroColors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('Detecta\nenfermedades\nal instante',
              style: TextStyle(fontFamily: AgroText.fontDisplay, fontSize: 28, height: 1.1, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Apunta la cámara a cualquier hoja, fruta o verdura y obtén el diagnóstico.',
              style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Get.toNamed(AgroRoutes.camera);
                await Future.delayed(const Duration(milliseconds: 500)); // Da tiempo para que SQLite guarde
                controller.loadLastScan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AgroColors.greenLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear cultivo ahora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 16, fontWeight: FontWeight.bold, color: AgroColors.textPrimary)),
        GestureDetector(
          onTap: onTap,
          child: Text(action, style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 14, color: AgroColors.green, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildHorizontalDiseaseList() {
    final diseases = [
      {'name': 'Mancha Bacteriana', 'science': 'Bacterial Spot', 'color': AgroColors.yellow},
      {'name': 'Tizón Temprano', 'science': 'Early Blight', 'color': AgroColors.orange},
      {'name': 'Sano', 'science': 'Healthy', 'color': AgroColors.healthy},
      {'name': 'Tizón Tardío', 'science': 'Late Blight', 'color': AgroColors.red},
      {'name': 'Moho de la Hoja', 'science': 'Leaf Mold', 'color': AgroColors.brown},
      {'name': 'Mancha por Septoria', 'science': 'Septoria Leaf Spot', 'color': AgroColors.orange},
      {'name': 'Mancha Blanca', 'science': 'Target Spot', 'color': AgroColors.textHint},
      {'name': 'Virus del Mosaico', 'science': 'Tomato Mosaic Virus', 'color': AgroColors.purple},
      {'name': 'Araña Roja', 'science': 'Two Spotted Spider Mite', 'color': AgroColors.red},
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: diseases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = diseases[index];
          return Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AgroColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AgroColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AgroColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(item['science'] as String, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AgroColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyScanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AgroColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AgroColors.border, style: BorderStyle.none),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AgroColors.border, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.history_toggle_off, color: AgroColors.textHint),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('No hay ningún registro reciente. Escanea tu primer cultivo.', 
              style: TextStyle(color: AgroColors.textHint, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScan(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AgroColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AgroColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AgroColors.green, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.document_scanner_outlined, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(controller.lastScanName.value, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AgroColors.textPrimary))),
                const SizedBox(height: 4),
                Obx(() => Text('${controller.locationName.value} · ${controller.lastScanTime.value}', 
                  style: const TextStyle(fontSize: 12, color: AgroColors.textHint))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AgroColors.yellowLight, borderRadius: BorderRadius.circular(12)),
            child: Obx(() => Text(controller.lastScanConfidence.value, 
              style: const TextStyle(color: AgroColors.orange, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AgroColors.greenFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AgroColors.yellow, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AGRONOMÍA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AgroColors.green, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Obx(() => Text(controller.tipOfTheDay.value, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AgroColors.textPrimary, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(HomeController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: AgroColors.surface,
        border: Border(top: BorderSide(color: AgroColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AgroColors.green,
        unselectedItemColor: AgroColors.textHint,
        onTap: (i) async {
          if (i == 1) Get.toNamed(AgroRoutes.map);
          if (i == 2) {
             await Get.toNamed(AgroRoutes.camera);
             await Future.delayed(const Duration(milliseconds: 500)); // Da tiempo para que SQLite guarde
             controller.loadLastScan();
          }
          if (i == 3) Get.toNamed(AgroRoutes.history);
          if (i == 4) Get.toNamed(AgroRoutes.forum);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          const BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          BottomNavigationBarItem(
            // Botón central estilo "Tomar"
            icon: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AgroColors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
            ),
            label: 'Tomar',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'Historial'),
          const BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Foro'),
        ],
      ),
    );
  }
}