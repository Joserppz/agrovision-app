import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../core/constants.dart';
import '../core/exceptions.dart' as agro_ex;
import 'api_service.dart';
import 'local_db_service.dart';

class ScanService {
  final ApiService     _api;
  final LocalDbService _db;
  final _uuid = const Uuid();

  ScanService(this._api, this._db);

  // Cambia a true para probar sin backend ni planta real
  static const bool _demoMode = false;

  Future<ScanResult> analyzeImage({
    required File   imageFile,
    required bool   isOnline,
    double?         latitude,
    double?         longitude,
    String?         locationName,
  }) async {
    final scanId = _uuid.v4();

    // ── MODO DEMO ────────────────────────────────────────────────────────────
    if (_demoMode) {
      await Future.delayed(const Duration(seconds: 2));
      final demo = ScanResult(
        id:           scanId,
        diseaseClass: 'Late-Blight',
        confidence:   0.874,
        treatment:    'Aislar las plantas afectadas.\nAplicar fungicida a base de cobre.\nReducir riego por aspersión.',
        latitude:     latitude,
        longitude:    longitude,
        locationName: locationName ?? 'La Paz, Bolivia',
        timestamp:    DateTime.now(),
        imagePath:    imageFile.path,
        isSynced:     false,
      );
      await _db.saveScan(demo);
      return demo;
    }

    // ── SIN CONEXIÓN → guardar en cola ───────────────────────────────────────
    if (!isOnline) {
      await _savePending(
        scanId:       scanId,
        imagePath:    imageFile.path,
        latitude:     latitude,
        longitude:    longitude,
        locationName: locationName,
      );
      throw agro_ex.NoConnectionException('No internet connection');
    }

    // ── MODO REAL → enviar al backend ─────────────────────────────────────────
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'scan_$scanId.jpg',
        ),
        if (latitude  != null) 'latitude':  latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        'scan_id': scanId,
      });

      final response = await _api.postMultipart<Map<String, dynamic>>(
        '/analyze',
        formData,
      );

      final data = response.data!;
      print('📦 Respuesta backend: $data');

      // Si Gemini dice que no es planta → informar al usuario
      if (data['is_plant'] == false) {
        throw const agro_ex.LowConfidenceException(0.0);
      }

      final confidence = (data['confidence'] as num).toDouble();

      // Threshold bajo (0.10) para que Gemini casi siempre pase
      if (confidence < AgroConfig.yoloThreshold) {
        throw agro_ex.LowConfidenceException(confidence);
      }

      final result = ScanResult(
        id:           data['id'] as String? ?? scanId,
        diseaseClass: data['disease_class'] as String? ?? 'Other',
        confidence:   confidence,
        treatment:    data['treatment'] as String? ?? '',
        latitude:     latitude,
        longitude:    longitude,
        locationName: data['location_name'] as String? ?? locationName,
        timestamp:    DateTime.now(),
        imagePath:    imageFile.path,
        isSynced:     true,
      );

      await _db.saveScan(result);
      return result;

    } on agro_ex.AgroException {
      rethrow;
    } catch (e) {
      throw agro_ex.AgroException(
        'Error al analizar la imagen',
        technicalDetail: e.toString(),
      );
    }
  }

  Future<void> _savePending({
    required String scanId,
    required String imagePath,
    double?  latitude,
    double?  longitude,
    String?  locationName,
  }) async {
    await _db.savePendingScan(
      scanId:       scanId,
      imagePath:    imagePath,
      latitude:     latitude,
      longitude:    longitude,
      locationName: locationName,
    );
  }
}