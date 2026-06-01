// Errores tipados de AgroVision
// Cada capa lanza estos en lugar de strings sueltos

class AgroException implements Exception {
  final String message;
  final String? technicalDetail;

  const AgroException(this.message, {this.technicalDetail});

  @override
  String toString() => 'AgroException: $message';
}

// El backend respondió pero con error
class BackendException extends AgroException {
  final int? statusCode;

  const BackendException(super.message, {this.statusCode, super.technicalDetail});
}

// No hay internet y la operación lo requiere
class NoConnectionException extends AgroException {
  const NoConnectionException()
      : super('Sin conexión a internet. El resultado se guardó localmente.');
}

// El modelo no detectó nada con suficiente confianza
class LowConfidenceException extends AgroException {
  final double confidence;

  const LowConfidenceException(this.confidence)
      : super(
          'No se detectó ninguna enfermedad conocida. '
          'Intenta con mejor iluminación o acerca más la cámara.',
        );
}

// Timeout al conectar con el backend
class TimeoutException extends AgroException {
  const TimeoutException()
      : super('El servidor tardó demasiado en responder. Intenta de nuevo.');
}

// Error de cámara
class CameraException extends AgroException {
  const CameraException(super.message);
}

// Error de base de datos local
class LocalDbException extends AgroException {
  const LocalDbException(super.message, {super.technicalDetail});
}

// Error de autenticación
class AuthException extends AgroException {
  const AuthException(super.message);
}

// Extensión para mostrar el mensaje al usuario con GetX Snackbar
extension AgroExceptionUI on AgroException {
  String get userMessage => message;
}