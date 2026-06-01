import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/routes.dart';
import 'core/bindings.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:      Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Supabase — solo si las keys están configuradas
  if (AgroConfig.supabaseUrl != 'TU_SUPABASE_URL') {
    await Supabase.initialize(
      url:    AgroConfig.supabaseUrl,
      anonKey: AgroConfig.supabaseAnonKey,
    );
  }

  runApp(const AgroVisionApp());
}

class AgroVisionApp extends StatelessWidget {
  const AgroVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title:           'AgroVision',
      debugShowCheckedModeBanner: false,
      theme:           AgroTheme.light,
      initialRoute:    AgroRoutes.home,
      initialBinding: InitialBinding(),
      getPages:        AgroPages.pages,

      // Traducciones de GetX (español por defecto)
      locale:          const Locale('es', 'BO'),
      fallbackLocale:  const Locale('es', 'ES'),

      // Snackbar global con estilo AgroVision
      defaultTransition: Transition.fadeIn,
    );
  }
}