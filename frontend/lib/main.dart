import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants.dart';
import 'core/routes.dart';
import 'core/theme.dart';
// Importar providers para pre-inicializar la DB al arrancar
import 'services/local_db_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_BO');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  if (AgroConfig.supabaseUrl != 'TU_SUPABASE_URL') {
    await Supabase.initialize(
      url:     AgroConfig.supabaseUrl,
      anonKey: AgroConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: AgroVisionApp()));
}

class AgroVisionApp extends ConsumerWidget {
  const AgroVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-calentar la DB al arrancar la app
    // Si está cargando, mostrar splash; si hay error, mostrarlo
    final dbAsync = ref.watch(localDbProvider);

    return dbAsync.when(
      // DB lista → arrancar app completa
      data: (_) {
        final goRouter = ref.watch(routerProvider);
        return MaterialApp.router(
          title:                    'AgroVision',
          debugShowCheckedModeBanner: false,
          theme:                    AgroTheme.light,
          routerConfig:             goRouter,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'BO'),
            Locale('es', 'ES'),
          ],
        );
      },

      // DB cargando → splash minimalista
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AgroTheme.light,
        home: const Scaffold(
          backgroundColor: AgroColors.cream,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌱',
                    style: TextStyle(fontSize: 48)),
                SizedBox(height: 20),
                CircularProgressIndicator(color: AgroColors.green),
                SizedBox(height: 16),
                Text(
                  'Iniciando AgroVision...',
                  style: TextStyle(
                    fontFamily: AgroText.fontBody,
                    color:      AgroColors.brown,
                    fontSize:   14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Error al abrir DB → mostrar mensaje
      error: (err, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AgroColors.cream,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AgroColors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al iniciar la base de datos',
                    style: TextStyle(
                      fontFamily: AgroText.fontBody,
                      fontSize:   16,
                      fontWeight: FontWeight.w600,
                      color:      AgroColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: const TextStyle(
                      fontFamily: AgroText.fontBody,
                      fontSize:   12,
                      color:      AgroColors.brown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}