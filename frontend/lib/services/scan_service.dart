import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../core/constants.dart';
import '../core/exceptions.dart' as agro_ex;
import 'api_service.dart';
import 'local_db_service.dart';

class ScanService {
  final ApiService    _api;
  final LocalDbService _db;
  final _uuid = const Uuid();

  ScanService(this._api, this._db);

  /// Envía la imagen al backend de FastAPI y devuelve el resultado.
  /// Si no hay internet lanza [NoConnectionException] y el controller
  /// lo guarda localmente.
  Future<ScanResult> analyzeImage({
    required File imageFile,
    required bool isOnline,
    double?      latitude,
    double?      longitude,
    String?      locationName,
  }) async {
    final scanId = _uuid.v4();

    if (!isOnline) {
      // Guardamos pendiente y lanzamos excepción informativa
      await _savePending(
        scanId:       scanId,
        imagePath:    imageFile.path,
        latitude:     latitude,
        longitude:    longitude,
        locationName: locationName,
      );
      throw const agro_ex.NoConnectionException();
    }

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
        '/scan',
        formData,
      );

      final json = response.data!;

      // Validar threshold de confianza
      final confidence = (json['confidence'] as num).toDouble();
      if (confidence < AgroConfig.yoloThreshold) {
        throw agro_ex.LowConfidenceException(confidence);
      }

      final result = ScanResult.fromJson({
        ...json,
        'id':            scanId,
        'timestamp':     DateTime.now().toIso8601String(),
        'latitude':      latitude,
        'longitude':     longitude,
        'location_name': locationName,
      });

      // Guardamos en SQLite local también (historial siempre local)
      await _db.saveScan(result.copyWith(isSynced: true));

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