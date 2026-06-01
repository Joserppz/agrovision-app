// controllers/forum_controller.dart
import 'package:get/get.dart';
import '../services/forum_service.dart';
import 'auth_controller.dart';

class ForumController extends GetxController {
  final ForumService   _forumService;
  final AuthController _auth;
  ForumController(this._forumService, this._auth);
}