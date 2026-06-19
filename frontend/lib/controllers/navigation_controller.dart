import 'package:flutter_riverpod/flutter_riverpod.dart';

// Un provider súper ligero para controlar el índice del BottomNavigationBar
final navigationProvider = StateProvider<int>((ref) => 0);