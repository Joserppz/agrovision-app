import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. ESTADO INMUTABLE
class ConnectivityState {
  final bool isOnline;
  final int pendingSyncCount;

  ConnectivityState({
    this.isOnline = true,
    this.pendingSyncCount = 0,
  });

  ConnectivityState copyWith({bool? isOnline, int? pendingSyncCount}) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

// 2. NOTIFIER
class ConnectivityController extends Notifier<ConnectivityState> {
  final _connectivity = Connectivity();
  StreamSubscription? _subscription;

  @override
  ConnectivityState build() {
    Future.microtask(() {
      _checkInitialStatus();
      _listenToChanges();
    });

    // Se ejecuta automáticamente si el provider se destruye
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return ConnectivityState();
  }

  Future<void> _checkInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _listenToChanges() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(dynamic result) {
    bool connected = false;
    
    // Compatibilidad segura para las diferentes versiones de connectivity_plus
    if (result is List<ConnectivityResult>) {
      connected = result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      connected = result == ConnectivityResult.mobile ||
                  result == ConnectivityResult.wifi ||
                  result == ConnectivityResult.ethernet;
    }

    if (state.isOnline != connected) {
      state = state.copyWith(isOnline: connected);
    }
  }

  void updatePendingCount(int count) {
    state = state.copyWith(pendingSyncCount: count);
  }
}

// 3. PROVIDER GLOBAL
final connectivityProvider = NotifierProvider<ConnectivityController, ConnectivityState>(() {
  return ConnectivityController();
});