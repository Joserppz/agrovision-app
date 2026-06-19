import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado inmutable del Foro
class ForumState {
  final bool isLoading;
  ForumState({this.isLoading = false});
}

// Notifier
class ForumController extends Notifier<ForumState> {
  @override
  ForumState build() {
    return ForumState();
  }
}

// Provider Global
final forumControllerProvider = NotifierProvider<ForumController, ForumState>(() {
  return ForumController();
});