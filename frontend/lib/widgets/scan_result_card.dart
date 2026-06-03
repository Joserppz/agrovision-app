import '../core/constants.dart';
import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import 'confidence_badge.dart';

class ScanResultCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback? onTap;

  const ScanResultCard({super.key, required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      // Nombre común (IA o Constantes)
                      Text(
                        result.displayName,
                        style: const TextStyle(
                          fontFamily: AgroText.fontDisplay,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AgroColors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Nombre científico
                      Text(
                        result.scientificName,
                        style: const TextStyle(
                          fontFamily: AgroText.fontBody,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AgroColors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConfidenceBadge(confidence: result.confidence),
                    const SizedBox(height: 4),
                    _SeverityChip(level: result.severityLevel),
                  ],
                ),
              ],
            ),
            
            // NUEVO: Mostrar un extracto de la descripción detallada si existe
            if (result.description != null && result.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                result.description!,
                style: const TextStyle(
                  fontFamily: AgroText.fontBody,
                  fontSize: 12,
                  color: AgroColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (result.hasLocation) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AgroColors.brown),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      result.locationName ??
                          'Lat: ${result.latitude!.toStringAsFixed(4)}°, Lon: ${result.longitude!.toStringAsFixed(4)}°',
                      style: const TextStyle(
                        fontFamily: AgroText.fontBody,
                        fontSize: 11,
                        color: AgroColors.brown,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (!result.isSynced) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 12, color: AgroColors.brown.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    'Pendiente de sincronizar',
                    style: TextStyle(
                      fontFamily: AgroText.fontBody,
                      fontSize: 10,
                      color: AgroColors.brown.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String level;
  const _SeverityChip({required this.level});

  String get _label {
    switch (level) {
      case 'critical': return 'CRÍTICO';
      case 'moderate': return 'MODERADO';
      case 'healthy':  return 'SANO';
      default:         return 'DESCONOCIDO';
    }
  }

  Color get _color => DiseaseLabels.colorForLevel(level);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: AgroText.fontBody,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}