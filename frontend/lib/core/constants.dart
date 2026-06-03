import 'package:flutter/material.dart';

// ─── Paleta oficial AgroVision ────────────────────────────────────────────────
class AgroColors {
  AgroColors._();

  static const green       = Color(0xFF2D5A27); // Verde Bosque — botones primarios
  static const greenLight  = Color(0xFF3D7A35); // Verde hover
  static const greenFaint  = Color(0xFFEEF4EC); // Verde fondo suave
  static const yellow      = Color(0xFFFBB03B); // Amarillo Sol — alertas, confianza
  static const yellowLight = Color(0xFFFFF3D6); // Amarillo fondo
  static const brown       = Color(0xFF6B4423); // Café Tierra — subtítulos
  static const cream       = Color(0xFFFDFBF7); // Crema Orgánico — fondo app
  static const red         = Color(0xFFC0392B); // Enfermedad crítica
  static const orange      = Color(0xFFE67E22); // Enfermedad moderada
  static const purple      = Color(0xFF8E44AD); // Arañuela
  static const healthy     = Color(0xFF27AE60); // Planta sana

  // Escala de grises sobre crema
  static const textPrimary   = Color(0xFF1A2E14);
  static const textSecondary = Color(0xFF6B4423);
  static const textHint      = Color(0xFFADA89F);
  static const border        = Color(0xFFECE8DF);
  static const surface       = Color(0xFFFFFFFF);
}

// ─── Tipografía ───────────────────────────────────────────────────────────────
class AgroText {
  AgroText._();

  static const fontDisplay = 'Playfair Display'; // headings grandes
  static const fontBody    = 'DM Sans';          // todo el resto
}

// ─── URLs y configuración ─────────────────────────────────────────────────────
class AgroConfig {
  AgroConfig._();

  // IP local de tu máquina (Activa para tus pruebas)
  static const backendBaseUrl = 'https://agrovision-app-ba39.onrender.com'; 
  
  // IPs del equipo (Comentadas para no perderlas en el repositorio)
  // static const backendBaseUrl = 'http://192.168.0.223:8000'; 
  // static const backendBaseUrl = 'http://10.0.2.2:8000'; 

  // Supabase — reemplazar con los datos reales del proyecto
  static const supabaseUrl     = 'TU_SUPABASE_URL';
  static const supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';

  // IA externa
  static const geminiApiKey   = 'TU_GEMINI_KEY';
  static const plantnetApiKey = 'TU_PLANTNET_KEY';

  // Umbrales del modelo (Ajustado a 0.10 para evitar rechazos de cámara)
  static const yoloThreshold  = 0.10; 
  static const yoloHighConf   = 0.75; // confianza alta → color verde
  static const yoloMidConf    = 0.55; // confianza media → color amarillo

  // Timeouts HTTP
  static const httpConnectTimeout = Duration(seconds: 10);
  static const httpReceiveTimeout = Duration(seconds: 30);

  // OpenMeteo (sin API key)
  static const weatherBaseUrl = 'https://api.open-meteo.com/v1';

  // OSM Nominatim (sin API key)
  static const nominatimUrl = 'https://nominatim.openstreetmap.org';
}

// ─── Nombres de rutas GetX ────────────────────────────────────────────────────
class AgroRoutes {
  AgroRoutes._();

  static const home        = '/home';
  static const camera      = '/camera';
  static const loading     = '/loading';
  static const results     = '/results';
  static const map         = '/map';
  static const history     = '/history';
  static const forum       = '/forum';
  static const forumPost   = '/forum/post';
  static const login       = '/login';
  static const profile     = '/profile';
}

// ─── Claves para SecureStorage ────────────────────────────────────────────────
class AgroStorageKeys {
  AgroStorageKeys._();

  static const deviceId    = 'device_id';
  static const authToken   = 'auth_token';
  static const userEmail   = 'user_email';
  static const userId      = 'user_id';
}

// ─── Nombres de enfermedades (clases del modelo YOLO) ────────────────────────
class DiseaseLabels {
  DiseaseLabels._();

  static const Map<String, Map<String, String>> data = {
    'Late-Blight': {
      'name':    'Tizón Tardío',
      'science': 'Phytophthora infestans',
      'level':   'critical',
    },
    'Early-Blight': {
      'name':    'Tizón Temprano',
      'science': 'Alternaria solani',
      'level':   'moderate',
    },
    'Septoria-Leaf-Spot': {
      'name':    'Mancha Foliar',
      'science': 'Septoria lycopersici',
      'level':   'moderate',
    },
    'Spider-Mites': {
      'name':    'Arañuela Roja',
      'science': 'Tetranychus urticae',
      'level':   'moderate',
    },
    'Leaf-Mold': {
      'name':    'Moho de la Hoja',
      'science': 'Passalora fulva',
      'level':   'moderate',
    },
    'Target-Spot': {
      'name':    'Mancha Blanca',
      'science': 'Corynespora cassiicola',
      'level':   'moderate',
    },
    'Yellow-Leaf-Curl-Virus': {
      'name':    'Virus de la Cuchara',
      'science': 'Begomovirus',
      'level':   'critical',
    },
    'Mosaic-Virus': {
      'name':    'Virus del Mosaico',
      'science': 'Tobamovirus',
      'level':   'critical',
    },
    'Powdery-Mildew': {
      'name':    'Oídio',
      'science': 'Oidium neolycopersici',
      'level':   'moderate',
    },
    'Healthy': {
      'name':    'Planta Sana',
      'science': 'Sin enfermedad detectada',
      'level':   'healthy',
    },
  };

  static Map<String, String> get(String classLabel) {
    return data[classLabel] ?? {
      'name':    classLabel,
      'science': '',
      'level':   'unknown',
    };
  }

  static Color colorForLevel(String level) {
    switch (level) {
      case 'critical': return AgroColors.red;
      case 'moderate': return AgroColors.orange;
      case 'healthy':  return AgroColors.healthy;
      default:         return AgroColors.yellow;
    }
  }
}