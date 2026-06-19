import '../core/constants.dart';
import 'package:flutter/material.dart';
import '../core/plantae_dictionary.dart'; // Ajusta la ruta correcta

class ScanResult {
  final String id;
  final String diseaseClass;   // clase exacta del modelo: "Late-Blight"
  final String? plantClass;    // NUEVO: clase exacta de la planta: "apple", "tomato"
  final double confidence;      // 0.0 a 1.0
  final String? plantCategory;  // 'Fruta', 'Verdura', 'Flor', 'Planta', 'Otros'
  final String? description;    // Descripción detallada de Groq
  final String? diseaseName;    // Nombre común de la IA
  final bool isPlant;           // Validación de la IA
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
    this.plantClass,
    required this.confidence,
    this.plantCategory,
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

  // --- GETTERS DE ENFERMEDADES ---
  String get displayName => diseaseName ?? DiseaseLabels.get(diseaseClass)['name'] ?? diseaseClass;
  String get scientificName => DiseaseLabels.get(diseaseClass)['science'] ?? '';
  String get severityLevel => DiseaseLabels.get(diseaseClass)['level'] ?? 'unknown';
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  Color get severityColor => DiseaseLabels.colorForLevel(severityLevel);
  bool get hasLocation => latitude != null && longitude != null;

  // --- NUEVOS GETTERS DE PLANTA (Requiere plantaeDetails en constants.dart) ---
  String get plantName => plantaeDetails[plantClass]?['nombre'] ?? plantClass ?? 'Desconocido';
  String get plantBenefits => plantaeDetails[plantClass]?['beneficios'] ?? 'No disponible';
  String get plantSeason => plantaeDetails[plantClass]?['temporada'] ?? 'No disponible';
  String get plantVitamins => plantaeDetails[plantClass]?['vitaminas'] ?? 'No disponible';

  Map<String, dynamic> toMap() => {
    'id':            id,
    'diseaseClass':  diseaseClass,
    'plantClass':    plantClass,
    'confidence':    confidence,
    'plantCategory': plantCategory,
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

  factory ScanResult.fromMap(Map<String, dynamic> map) => ScanResult(
    id:            map['id'] as String,
    diseaseClass:  map['diseaseClass'] as String,
    plantClass:    map['plantClass'] as String?,
    confidence:    (map['confidence'] as num).toDouble(),
    plantCategory: map['plantCategory'] as String?,
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

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id:            json['id']?.toString() ?? '',
    diseaseClass:  json['disease_class']?.toString() ?? 'Unknown',
    plantClass:    json['plant_class']?.toString(), 
    diseaseName:   json['diseaseName']?.toString(), 
    plantCategory: json['plantCategory']?.toString(), 
    description:   json['description']?.toString(),
    isPlant:       json['is_plant'] ?? true,
    confidence:    (json['confidence'] as num?)?.toDouble() ?? 0.0,
    treatment:     json['treatment']?.toString(),
    latitude:      (json['latitude'] as num?)?.toDouble(),
    longitude:     (json['longitude'] as num?)?.toDouble(),
    locationName:  json['location_name']?.toString(),
    timestamp:     json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    imagePath:     null,
    isSynced:      true,
  );

  ScanResult copyWith({
    String? id,
    String? diseaseName,
    String? plantClass,
    String? plantCategory,
    String? treatment,
    bool? isSynced,
    double? latitude,
    double? longitude,
    String? locationName,
    String? imagePath,
  }) => ScanResult(
    id:            id ?? this.id,
    diseaseClass:  diseaseClass,
    plantClass:    plantClass ?? this.plantClass,
    confidence:    confidence,
    plantCategory: plantCategory ?? this.plantCategory,
    description:   description,
    diseaseName:   diseaseName ?? this.diseaseName,
    isPlant:       isPlant,
    treatment:     treatment ?? this.treatment,
    latitude:      latitude ?? this.latitude,
    longitude:     longitude ?? this.longitude,
    locationName:  locationName ?? this.locationName,
    timestamp:     timestamp,
    imagePath:     imagePath ?? this.imagePath,
    isSynced:      isSynced ?? this.isSynced,
  );
}