import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../core/constants.dart';

// Usamos HookWidget en vez de StatefulWidget (100% Arquitectura Limpia)
class LoadingScreen extends HookWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Procesando imagen...',
      'Consultando modelo YOLOv8...',
      'Detectando patrones foliares...',
      'Buscando tratamiento en Supabase...',
    ];
    
    // Estado local manejado por Hooks
    final stepIndex = useState(0);

    // Controlador de animación
    final ctrl = useAnimationController(duration: const Duration(seconds: 1));
    final pulse = useAnimation(Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    ));

    // useEffect reemplaza a initState y dispose
    useEffect(() {
      ctrl.repeat(reverse: true);
      
      bool isActive = true;
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!isActive) return false;
        stepIndex.value = (stepIndex.value + 1) % steps.length;
        return true;
      });
      
      return () => isActive = false; // Se ejecuta al destruir la pantalla
    }, const []);

    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AgroColors.greenFaint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AgroColors.green.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.eco_outlined, color: AgroColors.green, size: 48),
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(color: AgroColors.green, strokeWidth: 3),
                ),
                const SizedBox(height: 32),
                Text(
                  'Analizando cultivo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AgroColors.green),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    steps[stepIndex.value],
                    key: ValueKey(stepIndex.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AgroColors.brown),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _Dot(delay: i * 200)),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AgroColors.greenFaint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AgroColors.green.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: AgroColors.green, size: 14),
                      SizedBox(width: 8),
                      Text('FastAPI → YOLOv8 → Supabase', style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, color: AgroColors.green, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends HookWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(duration: const Duration(milliseconds: 800));
    final anim = useAnimation(Tween<double>(begin: 0.4, end: 1.0).animate(ctrl));

    useEffect(() {
      bool isActive = true;
      Future.delayed(Duration(milliseconds: delay), () {
        if (isActive) ctrl.repeat(reverse: true);
      });
      return () => isActive = false;
    }, const []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Opacity(
        opacity: anim,
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: AgroColors.green, shape: BoxShape.circle),
        ),
      ),
    );
  }
}