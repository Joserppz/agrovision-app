import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';
import '../services/local_db_service.dart';
import '../core/constants.dart';

// 1. EL ESTADO INMUTABLE
class HomeState {
  final String greeting;
  final String temperature;
  final String humidity;
  final String locationName;
  final String tipOfTheDay;
  final bool hasLastScan;
  final String lastScanName;
  final String lastScanTime;
  final String lastScanConfidence;

  HomeState({
    this.greeting = 'Buenos días',
    this.temperature = '--',
    this.humidity = '--',
    this.locationName = 'Buscando...',
    this.tipOfTheDay = '',
    this.hasLastScan = false,
    this.lastScanName = '',
    this.lastScanTime = '',
    this.lastScanConfidence = '',
  });

  HomeState copyWith({
    String? greeting, String? temperature, String? humidity,
    String? locationName, String? tipOfTheDay, bool? hasLastScan,
    String? lastScanName, String? lastScanTime, String? lastScanConfidence,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      locationName: locationName ?? this.locationName,
      tipOfTheDay: tipOfTheDay ?? this.tipOfTheDay,
      hasLastScan: hasLastScan ?? this.hasLastScan,
      lastScanName: lastScanName ?? this.lastScanName,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      lastScanConfidence: lastScanConfidence ?? this.lastScanConfidence,
    );
  }
}

// 2. EL NOTIFIER (Lógica de Negocio)
class HomeController extends Notifier<HomeState> {
  final WeatherService _weatherService = WeatherService();

  final List<String> _tips = [
    'El riego temprano reduce el riesgo de hongos foliares.',
    'Asegura un buen drenaje para evitar la pudrición de raíces.',
    'Rotar cultivos anualmente previene plagas persistentes.',
    'Limpia tus herramientas después de podar plantas enfermas.',
    'La ventilación adecuada disminuye la humedad retenida.',
    'Observa el envés de las hojas, ahí se esconden muchas plagas.',
    'Aplica fertilizantes lejos del tallo principal para evitar quemaduras.'
  ];

  @override
  HomeState build() {
    // Inicialización asíncrona segura
    Future.microtask(() {
      _setDynamicGreeting();
      _setTipOfTheDay();
      _loadRealLocationAndWeather();
      loadLastScan();
    });
    return HomeState();
  }

  void _setDynamicGreeting() {
    final hour = DateTime.now().hour;
    String newGreeting = hour < 12 ? 'Buenos días,' : (hour < 19 ? 'Buenas tardes,' : 'Buenas noches,');
    state = state.copyWith(greeting: newGreeting);
  }

  void _setTipOfTheDay() {
    final index = DateTime.now().weekday - 1;
    state = state.copyWith(tipOfTheDay: _tips[index]);
  }

  Future<void> _loadRealLocationAndWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(locationName: 'GPS apagado');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(locationName: 'Sin permiso');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      String locName = 'Ubicación local';
      if (placemarks.isNotEmpty) {
        locName = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? locName;
      }

      final data = await _weatherService.getCurrentWeather(position.latitude, position.longitude);
      if (data != null && data['current'] != null) {
        state = state.copyWith(
          locationName: locName,
          temperature: '${data['current']['temperature_2m'].round()}°C',
          humidity: '${data['current']['relative_humidity_2m'].round()}%',
        );
      } else {
        state = state.copyWith(locationName: locName);
      }
    } catch (e) {
      state = state.copyWith(locationName: 'Sin conexión');
    }
  }

  Future<void> loadLastScan() async {
    try {
      final dbService = ref.read(localDbProvider);
      await dbService.init(); 
      final scans = await dbService.getAllScans(limit: 1); 
      
      if (scans.isNotEmpty) {
        final lastScan = scans.first;
        state = state.copyWith(
          hasLastScan: true,
          lastScanName: lastScan.displayName,
          lastScanConfidence: lastScan.confidencePercent,
          lastScanTime: _getTimeAgo(lastScan.timestamp),
        );
      } else {
        state = state.copyWith(hasLastScan: false);
      }
    } catch (e) {
      state = state.copyWith(hasLastScan: false);
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
}

// 3. EXPORTAMOS EL CONTROLADOR
final homeControllerProvider = NotifierProvider<HomeController, HomeState>(() {
  return HomeController();
});