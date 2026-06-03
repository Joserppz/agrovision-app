import '../core/constants.dart';
import 'package:flutter/material.dart';

class ScanResult {
  final String id;
  final String diseaseClass;   // clase exacta del modelo: "Late-Blight"
  final double confidence;      // 0.0 a 1.0
  final String? description;    // NUEVO: Descripción detallada de Groq
  final String? diseaseName;    // NUEVO: Nombre común de la IA
  final bool isPlant;           // NUEVO: Validación de la IA
  final String? treatment;      // texto del tratamiento
  final double? latitude;
  final double? longitude;
  final String? locationName;   // nombre legible: "La Paz, Bolivia"
  final DateTime timestamp;
  final String? imagePath;      // ruta local de la imagen
  final bool isSynced;          // si ya se subió al servidor

  const ScanResult({
    required this.id,
    required this.diseaseClass,
    required this.confidence,
    this.description,
    this.diseaseName,
    this.isPlant = true,
    this.treatment,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.timestamp,
    this.imagePath,
    this.isSynced = false,
  });

  // Si la IA mandó un nombre específico, lo usa. Si no, busca en las constantes.
  String get displayName => diseaseName ?? DiseaseLabels.get(diseaseClass)['name'] ?? diseaseClass;

  // Nombre científico
  String get scientificName => DiseaseLabels.get(diseaseClass)['science'] ?? '';

  // Nivel de severidad: critical / moderate / healthy / unknown
  String get severityLevel => DiseaseLabels.get(diseaseClass)['level'] ?? 'unknown';

  // Porcentaje para mostrar en UI
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  // Color según nivel
  Color get severityColor => DiseaseLabels.colorForLevel(severityLevel);

  // Si tiene coordenadas GPS
  bool get hasLocation => latitude != null && longitude != null;

  // Para serializar y guardar en SQLite
  Map<String, dynamic> toMap() => {
    'id':            id,
    'diseaseClass':  diseaseClass,
    'confidence':    confidence,
    'description':   description,
    'diseaseName':   diseaseName,
    'isPlant':       isPlant ? 1 : 0,
    'treatment':     treatment,
    'latitude':      latitude,
    'longitude':     longitude,
    'locationName':  locationName,
    'timestamp':     timestamp.toIso8601String(),
    'imagePath':     imagePath,
    'isSynced':      isSynced ? 1 : 0,
  };

  // Para reconstruir desde SQLite
  factory ScanResult.fromMap(Map<String, dynamic> map) => ScanResult(
    id:            map['id'] as String,
    diseaseClass:  map['diseaseClass'] as String,
    confidence:    (map['confidence'] as num).toDouble(),
    description:   map['description'] as String?,
    diseaseName:   map['diseaseName'] as String?,
    isPlant:       (map['isPlant'] as int? ?? 1) == 1,
    treatment:     map['treatment'] as String?,
    latitude:      (map['latitude'] as num?)?.toDouble(),
    longitude:     (map['longitude'] as num?)?.toDouble(),
    locationName:  map['locationName'] as String?,
    timestamp:     DateTime.parse(map['timestamp'] as String),
    imagePath:     map['imagePath'] as String?,
    isSynced:      (map['isSynced'] as int? ?? 0) == 1,
  );

  // Para JSON del backend (Blindado contra nulos y tipos de datos erróneos)
  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id:            json['id']?.toString() ?? '',
    diseaseClass:  json['disease_class']?.toString() ?? 'Unknown',
    diseaseName:   json['diseaseName']?.toString(), 
    description:   json['description']?.toString(),
    isPlant:       json['is_plant'] ?? true,
    confidence:    (json['confidence'] as num?)?.toDouble() ?? 0.0,
    treatment:     json['treatment']?.toString(),
    // El .toDouble() seguro evita los crasheos de GPS
    latitude:      (json['latitude'] as num?)?.toDouble(),
    longitude:     (json['longitude'] as num?)?.toDouble(),
    locationName:  json['location_name']?.toString(),
    timestamp:     json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    imagePath:     null,
    isSynced:      true,
  );

  ScanResult copyWith({
    String? treatment,
    bool? isSynced,
    String? locationName,
    String? imagePath,
  }) => ScanResult(
    id:           id,
    diseaseClass: diseaseClass,
    confidence:   confidence,
    description:  description,
    diseaseName:  diseaseName,
    isPlant:      isPlant,
    treatment:    treatment ?? this.treatment,
    latitude:     latitude,
    longitude:    longitude,
    locationName: locationName ?? this.locationName,
    timestamp:    timestamp,
    imagePath:    imagePath ?? this.imagePath,
    isSynced:     isSynced ?? this.isSynced,
  );
}