// Errores tipados de AgroVision
// Cada capa lanza estos en lugar de strings sueltos

class AgroException implements Exception {
  final String message;
  final String? technicalDetail;

  const AgroException(this.message, {this.technicalDetail});

  @override
  String toString() => 'AgroException: $message';
}

class BackendException extends AgroException {
  final int? statusCode;
  const BackendException(super.message, {this.statusCode, super.technicalDetail});
}

class NoConnectionException extends AgroException {
  const NoConnectionException(String s)
      : super('Sin conexión a internet. El resultado se guardó localmente.');
}

class LowConfidenceException extends AgroException {
  final double confidence;
  const LowConfidenceException(this.confidence)
      : super(
          'No se detectó ninguna enfermedad conocida. '
          'Intenta con mejor iluminación o acerca más la cámara.',
        );
}

class TimeoutException extends AgroException {
  const TimeoutException()
      : super('El servidor tardó demasiado en responder. Intenta de nuevo.');
}

class AgroCameraException extends AgroException {
  const AgroCameraException(super.message);
}

class LocalDbException extends AgroException {
  const LocalDbException(super.message, {super.technicalDetail});
}

class AuthException extends AgroException {
  const AuthException(super.message);
}

// Extensión para extraer el mensaje amigable para el usuario en la UI
extension AgroExceptionUI on AgroException {
  String get userMessage => message;
}