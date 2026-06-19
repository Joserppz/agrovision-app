import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Creamos un Provider para inyectar tu servicio de Auth
final authServiceProvider = Provider((ref) => AuthService());

// 1. ESTADO INMUTABLE
class AuthState {
  final bool isLoggedIn;
  final String userEmail;

  AuthState({
    this.isLoggedIn = false,
    this.userEmail = '',
  });

  AuthState copyWith({bool? isLoggedIn, String? userEmail}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

// 2. NOTIFIER
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(); // Estado inicial
  }

  void login(String email) {
    state = state.copyWith(isLoggedIn: true, userEmail: email);
  }

  void logout() {
    state = AuthState(); // Resetea el estado
  }
}

// 3. PROVIDER GLOBAL
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});