import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class WeatherService {
  Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lon) async {
    try {
      final url = '${AgroConfig.weatherBaseUrl}/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m&timezone=auto';
      final response = await http.get(Uri.parse(url)).timeout(AgroConfig.httpConnectTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}