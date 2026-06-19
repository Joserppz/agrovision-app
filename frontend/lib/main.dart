import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants.dart';
import 'core/routes.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_BO');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  if (AgroConfig.supabaseUrl != 'TU_SUPABASE_URL') {
    await Supabase.initialize(
      url: AgroConfig.supabaseUrl,
      anonKey: AgroConfig.supabaseAnonKey,
    );
  }

  // EL CAMBIO ESTRELLA: ProviderScope envuelve la App
  runApp(const ProviderScope(child: AgroVisionApp()));
}

// Convertimos a ConsumerWidget para poder leer los Providers
class AgroVisionApp extends ConsumerWidget {
  const AgroVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leemos el enrutador que creamos en el paso anterior
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AgroVision',
      debugShowCheckedModeBanner: false,
      theme: AgroTheme.light,
      
      routerConfig: goRouter,

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
  }
}