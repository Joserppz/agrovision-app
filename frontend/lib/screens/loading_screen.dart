import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  final _steps = [
    'Procesando imagen...',
    'Consultando modelo YOLOv8...',
    'Detectando patrones foliares...',
    'Buscando tratamiento en Supabase...',
  ];
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // Rota los textos de estado cada 1.5 segundos
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return false;
      setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AgroColors.greenFaint,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AgroColors.green.withOpacity(0.3),
                          width: 2),
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      color: AgroColors.green,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Spinner
                const SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(
                    color: AgroColors.green,
                    strokeWidth: 3,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Analizando cultivo',
                  style: Get.textTheme.titleLarge?.copyWith(
                    color: AgroColors.green,
                  ),
                ),

                const SizedBox(height: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _steps[_stepIndex],
                    key: ValueKey(_stepIndex),
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AgroColors.brown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _Dot(delay: i * 200)),
                ),

                const SizedBox(height: 48),

                // Info del flujo
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AgroColors.greenFaint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AgroColors.green.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          color: AgroColors.green, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'FastAPI → YOLOv8 → Supabase',
                        style: TextStyle(
                          fontFamily: AgroText.fontBody,
                          fontSize: 11,
                          color: AgroColors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: AgroColors.green,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}