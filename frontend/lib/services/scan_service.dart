import 'dart:io';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class ScanService {
  final ApiService _api;
  final LocalDbService _db;

  ScanService(this._api, this._db);

  Future<ScanResult> analyzeImage({
    required File imageFile,
    required bool isOnline,
    required dynamic mode,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Aquí implementas tu lógica de llamada a la IA (YOLO/Groq)
    // Usando _api para enviar la imagen y _db para operaciones locales
    return ScanResult(); 
  }
}