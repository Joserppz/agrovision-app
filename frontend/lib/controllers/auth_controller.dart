// controllers/auth_controller.dart
import 'package:get/get.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService;
  AuthController(this._authService);

  final isLoggedIn = false.obs;
  final userEmail  = ''.obs;
}