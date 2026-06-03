import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';
import '../services/local_db_service.dart'; // Ajusta la ruta si tu archivo está en otra carpeta
import '../core/constants.dart';

class HomeController extends GetxController {
  final WeatherService _weatherService = WeatherService();

  var greeting = 'Buenos días'.obs;
  var temperature = '--'.obs;
  var humidity = '--'.obs;
  var locationName = 'Buscando...'.obs; 
  var tipOfTheDay = ''.obs;

  // Lógica del último escaneo
  var hasLastScan = false.obs;
  var lastScanName = ''.obs;
  var lastScanTime = ''.obs;
  var lastScanConfidence = ''.obs;

  final List<String> _tips = [
    'Lunes: El riego temprano reduce el riesgo de hongos foliares.',
    'Martes: Asegura un buen drenaje para evitar la pudrición de raíces.',
    'Miércoles: Rotar cultivos anualmente previene plagas persistentes.',
    'Jueves: Limpia tus herramientas después de podar plantas enfermas.',
    'Viernes: La ventilación adecuada disminuye la humedad retenida.',
    'Sábado: Observa el envés de las hojas, ahí se esconden muchas plagas.',
    'Domingo: Aplica fertilizantes lejos del tallo principal para evitar quemaduras.'
  ];

  @override
  void onInit() {
    super.onInit();
    _setDynamicGreeting();
    _setTipOfTheDay();
    _loadRealLocationAndWeather();
    _loadLastScan();
  }

  void _setDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Buenos días,';
    } else if (hour < 19) {
      greeting.value = 'Buenas tardes,';
    } else {
      greeting.value = 'Buenas noches,';
    }
  }

  void _setTipOfTheDay() {
    final index = DateTime.now().weekday - 1;
    tipOfTheDay.value = _tips[index];
  }

  Future<void> _loadRealLocationAndWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationName.value = 'GPS apagado';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationName.value = 'Sin permiso';
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        locationName.value = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? 'Ubicación local';
      }

      final data = await _weatherService.getCurrentWeather(position.latitude, position.longitude);
      if (data != null && data['current'] != null) {
        temperature.value = '${data['current']['temperature_2m'].round()}°C';
        humidity.value = '${data['current']['relative_humidity_2m'].round()}%';
      }
    } catch (e) {
      locationName.value = 'Sin conexión';
    }
  }

  Future<void> _loadLastScan() async {
    try {
      final dbService = Get.find<LocalDbService>();
      final scans = await dbService.getAllScans(limit: 1); // Traemos solo el último
      
      if (scans.isNotEmpty) {
        final lastScan = scans.first;
        hasLastScan.value = true;
        
        // Usamos los getters que ya tienes definidos en tu ScanResult
        lastScanName.value = lastScan.displayName;
        lastScanConfidence.value = lastScan.confidencePercent;
        lastScanTime.value = _getTimeAgo(lastScan.timestamp);
      } else {
        hasLastScan.value = false;
      }
    } catch (e) {
      hasLastScan.value = false;
      debugPrint("Error al cargar el último escaneo desde BD: $e");
    }
  }

  String _getTimeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 1) return 'hace un momento';
    if (duration.inMinutes < 60) return 'hace ${duration.inMinutes} min';
    if (duration.inHours < 24) return 'hace ${duration.inHours} h';
    return 'hace ${duration.inDays} d';
  }

  void showComingSoonDialog() {
    Get.defaultDialog(
      title: 'Próximamente',
      middleText: 'El módulo de perfil y foro comunitario estará disponible en la próxima actualización.',
      textConfirm: 'Entendido',
      confirmTextColor: Colors.white,
      buttonColor: AgroColors.green,
      onConfirm: () => Get.back(),
    );
  }

  void showAllDiseasesDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AgroColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Text('Todas las enfermedades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AgroColors.textPrimary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('Mancha Bacteriana'), subtitle: Text('Bacterial Spot')),
                  ListTile(title: Text('Tizón Temprano'), subtitle: Text('Early Blight')),
                  ListTile(title: Text('Sano'), subtitle: Text('Healthy')),
                  ListTile(title: Text('Tizón Tardío'), subtitle: Text('Late Blight')),
                  ListTile(title: Text('Moho de la Hoja'), subtitle: Text('Leaf Mold')),
                  ListTile(title: Text('Mancha Foliar por Septoria'), subtitle: Text('Septoria Leaf Spot')),
                  ListTile(title: Text('Mancha Blanca'), subtitle: Text('Target Spot')),
                  ListTile(title: Text('Virus del Mosaico'), subtitle: Text('Tomato Mosaic Virus')),
                  ListTile(title: Text('Araña Roja'), subtitle: Text('Two Spotted Spider Mite')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}