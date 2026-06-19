import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../controllers/scan_controller.dart';
// import '../controllers/connectivity_controller.dart'; // Comentado temporalmente

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado del controlador
    final state = ref.watch(scanControllerProvider);
    final ctrl = ref.read(scanControllerProvider.notifier);
    
    // Simulación de conectividad hasta migrarla (Fase posterior)
    final bool isOnline = true; 

    if (!state.isCameraReady || ctrl.cameraController == null || !ctrl.cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AgroColors.yellow)),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / ctrl.cameraController!.value.aspectRatio,
                child: CameraPreview(ctrl.cameraController!),
              ),
            ),
          ),
          _buildVignette(),
          _buildTopBar(context, isOnline),
          _buildModeSelector(state, ctrl),
          _buildScanFrame(),
          _buildHint(),
          _buildBottomControls(context, state, ctrl),
        ],
      ),
    );
  }

  Widget _buildVignette() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isOnline) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? AgroColors.green.withOpacity(0.85) : AgroColors.brown.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isOnline ? Icons.memory_outlined : Icons.wifi_off_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'IA ACTIVA' : 'OFFLINE',
                      style: const TextStyle(fontFamily: AgroText.fontBody, color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(ScanStateData state, ScanController ctrl) {
    return Align(
      alignment: const Alignment(0, -0.75),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeButton(title: 'YOLO', mode: AnalysisMode.yolo, state: state, ctrl: ctrl),
            _ModeButton(title: 'GROQ', mode: AnalysisMode.groq, state: state, ctrl: ctrl),
            _ModeButton(title: 'HÍBRIDO', mode: AnalysisMode.hybrid, state: state, ctrl: ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: SizedBox(
        width: 240, height: 240,
        child: Stack(
          children: [..._corners(), _ScanLine()],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const size = 28.0; const width = 3.0; const color = AgroColors.yellow; const radius = 8.0;
    return [
      Positioned(top: 0, left: 0, child: Container(width: size, height: size, decoration: const BoxDecoration(border: Border(top: BorderSide(color: color, width: width), left: BorderSide(color: color, width: width)), borderRadius: BorderRadius.only(topLeft: Radius.circular(radius))))),
      Positioned(top: 0, right: 0, child: Container(width: size, height: size, decoration: const BoxDecoration(border: Border(top: BorderSide(color: color, width: width), right: BorderSide(color: color, width: width)), borderRadius: BorderRadius.only(topRight: Radius.circular(radius))))),
      Positioned(bottom: 0, left: 0, child: Container(width: size, height: size, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: color, width: width), left: BorderSide(color: color, width: width)), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(radius))))),
      Positioned(bottom: 0, right: 0, child: Container(width: size, height: size, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: color, width: width), right: BorderSide(color: color, width: width)), borderRadius: BorderRadius.only(bottomRight: Radius.circular(radius))))),
    ];
  }

  Widget _buildHint() {
    return Align(
      alignment: const Alignment(0, 0.35),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
        child: const Text('Centra la hoja dentro del marco', style: TextStyle(fontFamily: AgroText.fontBody, color: Colors.white70, fontSize: 13)),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, ScanStateData state, ScanController ctrl) {
    bool isBusy = state.status == ScanStatus.capturing || state.status == ScanStatus.analyzing;

    Future<void> handleAnalysis(Future<bool> Function() analysisAction) async {
      context.push(AgroRoutes.loading); // Muestra la pantalla de carga
      final success = await analysisAction();
      
      if (!context.mounted) return;
      
      if (success) {
        context.replace(AgroRoutes.results); // Vamos a resultados
      } else {
        context.pop(); // Quitamos la pantalla de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage), backgroundColor: AgroColors.red, duration: const Duration(seconds: 4))
        );
      }
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent]),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconButton(
              icon: Icons.photo_library_outlined,
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (picked != null) {
                  await handleAnalysis(() => ctrl.analyzeFromGallery(File(picked.path)));
                }
              },
            ),
            GestureDetector(
              onTap: isBusy ? null : () => handleAnalysis(ctrl.takePictureAndAnalyze),
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  color: Colors.white,
                ),
                child: isBusy
                    ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AgroColors.green, strokeWidth: 3))
                    : Container(margin: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
            _IconButton(
              icon: Icons.flip_camera_ios_outlined,
              onTap: () async { await ctrl.toggleCamera(); },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final AnalysisMode mode;
  final ScanStateData state;
  final ScanController ctrl;

  const _ModeButton({required this.title, required this.mode, required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isSelected = state.selectedMode == mode;
    return GestureDetector(
      onTap: () => ctrl.setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AgroColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AgroText.fontBody,
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat(reverse: true);
    _anim = Tween<double>(begin: 8, end: 224).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: _anim.value,
        left: 8, right: 8,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, AgroColors.yellow.withOpacity(0.9), Colors.transparent]),
            borderRadius: BorderRadius.circular(4),
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}