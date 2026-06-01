import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/local_db_service.dart';
import '../models/scan_result.dart';
import '../core/exceptions.dart';

class ScanService {
  final dio.Dio _dio = dio.Dio();
  
  // Recuerda usar tu IP local que descubrimos con el ipconfig
  final String _baseUrl = "http://192.168.1.204:8000";

  ScanService(ApiService find, LocalDbService find2);

  Future<ScanResult> analyzeImage({
    required File imageFile,
    required bool isOnline,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Si está offline, desviamos la lógica para guardar localmente
    if (!isOnline) {
      // Aquí simularás o guardarás en tu LocalDbService el pendiente
      throw NoConnectionException("Sin internet. El escaneo se guardó localmente en el historial.");
    }

    try {
      String fileName = imageFile.path.split('/').last;

      // Crear el formulario Multipart con la foto y los metadatos del GPS
      dio.FormData formData = dio.FormData.fromMap({
        "image": await dio.MultipartFile.fromFile(imageFile.path, filename: fileName),
        "latitude": latitude,
        "longitude": longitude,
        "location_name": locationName,
      });

      // Enviar la petición POST al backend
      final response = await _dio.post(
        "$_baseUrl/analyze",
        data: formData,
        options: dio.Options(
          headers: {
            "Accept": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        // Mapear el JSON de respuesta de Python al modelo tipado de tu Flutter
        return ScanResult.fromJson(response.data);
      } else {
        throw AgroException("El servidor respondió con un error al procesar.");
      }
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.connectionTimeout || 
          e.type == dio.DioExceptionType.connectionError) {
        throw AgroException("No se pudo conectar con el servidor de IA. Verifica que tu PC tenga el backend encendido.");
      }
      throw AgroException("Error en la comunicación con el backend: ${e.message}");
    } catch (e) {
      throw AgroException("Error inesperado en el servicio de escaneo: $e");
    }
  }
}