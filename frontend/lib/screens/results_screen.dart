import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants.dart';
import '../controllers/scan_controller.dart';
import '../widgets/confidence_badge.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ScanController>();

    return Obx(() {
      final result = ctrl.result.value;

      if (result == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: AgroColors.cream,
        body: Column(
          children: [
            // Imagen capturada con bounding box simulado
            _buildImageBand(ctrl),
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDiseaseCard(result),
                    const SizedBox(height: 12),
                    _buildTreatmentCard(result.treatment),
                    const SizedBox(height: 12),
                    if (result.hasLocation) _buildLocationCard(result),
                    if (result.hasLocation) const SizedBox(height: 12),
                    _buildActionRow(ctrl),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildImageBand(ScanController ctrl) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen real capturada
          ctrl.capturedImage.value != null
              ? Image.file(ctrl.capturedImage.value!, fit: BoxFit.cover)
              : Container(color: AgroColors.green.withOpacity(0.3)),

          // Overlay oscuro
          Container(color: Colors.black26),

          // Bounding box
          if (ctrl.result.value != null)
            Center(
              child: Container(
                width: 140, height: 110,
                decoration: BoxDecoration(
                  border: Border.all(color: AgroColors.yellow, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: const Offset(0, -22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AgroColors.yellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ctrl.result.value!.displayName,
                        style: const TextStyle(
                          fontFamily: AgroText.fontBody,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1000),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Badge confianza arriba derecha
          if (ctrl.result.value != null)
            Positioned(
              top: 12, right: 12,
              child: ConfidenceBadge(
                  confidence: ctrl.result.value!.confidence),
            ),

          // Botón volver arriba izquierda
          Positioned(
            top: 8, left: 8,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AgroColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AgroColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayName,
                      style: const TextStyle(
                        fontFamily: AgroText.fontDisplay,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AgroColors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.scientificName,
                      style: const TextStyle(
                        fontFamily: AgroText.fontBody,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AgroColors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              _SeverityBadge(level: result.severityLevel),
            ],
          ),

          const SizedBox(height: 14),

          // Barra de severidad
          const Text(
            'SEVERIDAD ESTIMADA',
            style: TextStyle(
              fontFamily: AgroText.fontBody,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AgroColors.brown,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: result.confidence,
              minHeight: 7,
              backgroundColor: AgroColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                result.severityColor,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tags del cultivo afectado
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(label: 'Tomate', color: AgroColors.green),
              _Tag(label: 'Papa',   color: AgroColors.green),
              if (result.severityLevel == 'critical')
                _Tag(label: 'Alta Humedad', color: AgroColors.yellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(String? treatment) {
    final steps = treatment != null
        ? treatment.split('\n').where((s) => s.trim().isNotEmpty).toList()
        : [
            'Aislar las plantas afectadas para evitar propagación.',
            'Aplicar fungicida a base de cobre (Bordeaux) cada 7 días.',
            'Reducir riego por aspersión y mejorar ventilación.',
            'Revisar plantas vecinas en radio de 3 metros.',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AgroColors.greenFaint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AgroColors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  color: AgroColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Tratamiento recomendado',
                style: TextStyle(
                  fontFamily: AgroText.fontBody,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AgroColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: AgroColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: AgroText.fontBody,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontFamily: AgroText.fontBody,
                      fontSize: 13,
                      color: AgroColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLocationCard(result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AgroColors.yellowLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgroColors.yellow.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COORDENADAS DEL ESCANEO',
            style: TextStyle(
              fontFamily: AgroText.fontBody,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AgroColors.brown,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AgroColors.brown, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.locationName ??
                      'Lat: ${result.latitude!.toStringAsFixed(4)}° · '
                      'Lon: ${result.longitude!.toStringAsFixed(4)}°',
                  style: const TextStyle(
                    fontFamily: AgroText.fontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AgroColors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AgroRoutes.map),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Ver en el mapa'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(ScanController ctrl) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Get.snackbar('✓ Guardado',
                  'El resultado se guardó en tu historial',
                  snackPosition: SnackPosition.BOTTOM);
              Get.offNamed(AgroRoutes.home);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Guardar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ctrl.reset();
              Get.offNamed(AgroRoutes.camera);
            },
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Nuevo scan'),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final String level;
  const _SeverityBadge({required this.level});

  String get _label {
    switch (level) {
      case 'critical': return 'CRÍTICO';
      case 'moderate': return 'MODERADO';
      case 'healthy':  return 'SANO ✓';
      default:         return 'DESCONOCIDO';
    }
  }

  Color get _color => DiseaseLabels.colorForLevel(level);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(_label,
      style: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _color,
        letterSpacing: 0.5,
      )),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
      style: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      )),
  );
}