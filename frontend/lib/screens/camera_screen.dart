import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../controllers/scan_controller.dart';
import '../controllers/connectivity_controller.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl         = Get.find<ScanController>();
    final connectivity = Get.find<ConnectivityController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // Validación reactiva: Si no está lista o el controlador es nulo, evita el renderizado nativo
        if (!ctrl.isCameraReady.value || ctrl.cameraController == null || !ctrl.cameraController!.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AgroColors.yellow),
          );
        }
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Preview de la cámara seguro bajo la validación del Obx
            CameraPreview(ctrl.cameraController!),

            // Overlay oscuro en los bordes
            _buildVignette(),

            // Barra superior
            _buildTopBar(connectivity),

            // Marco de enfoque con línea de escaneo
            _buildScanFrame(),

            // Hint de usuario
            _buildHint(),

            // Controles inferiores
            _buildBottomControls(ctrl),
          ],
        );
      }),
    );
  }

  Widget _buildVignette() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.35),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ConnectivityController connectivity) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Botón volver
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
              // Badge IA activa / offline
              Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: connectivity.isOnline.value
                      ? AgroColors.green.withOpacity(0.85)
                      : AgroColors.brown.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectivity.isOnline.value
                          ? Icons.memory_outlined
                          : Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      connectivity.isOnline.value ? 'IA ACTIVA' : 'OFFLINE',
                      style: const TextStyle(
                        fontFamily: AgroText.fontBody,
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          children: [
            // Esquinas del marco
            ..._corners(),
            // Línea de escaneo animada
            _ScanLine(),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const size  = 28.0;
    const width = 3.0;
    const color = AgroColors.yellow;
    const radius = 8.0;

    return [
      // Top-left
      Positioned(
        top: 0, left: 0,
        child: Container(
          width: size, height: size,
          decoration: const BoxDecoration(
            border: Border(
              top:  BorderSide(color: color, width: width),
              left: BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius)),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 0, right: 0,
        child: Container(
          width: size, height: size,
          decoration: const BoxDecoration(
            border: Border(
              top:   BorderSide(color: color, width: width),
              right: BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(radius)),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: Container(
          width: size, height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: width),
              left:   BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(radius)),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: Container(
          width: size, height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: width),
              right:  BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(radius)),
          ),
        ),
      ),
    ];
  }

  Widget _buildHint() {
    return Align(
      alignment: const Alignment(0, 0.35),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Centra la hoja dentro del marco',
          style: TextStyle(
            fontFamily: AgroText.fontBody,
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ScanController ctrl) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Galería
            _IconButton(
              icon: Icons.photo_library_outlined,
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85);
                if (picked != null) {
                  await ctrl.analyzeFromGallery(File(picked.path));
                }
              },
            ),

            // Disparador principal
            Obx(() => GestureDetector(
              onTap: ctrl.state.value == ScanState.capturing ||
                      ctrl.state.value == ScanState.analyzing
                  ? null
                  : ctrl.takePictureAndAnalyze,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 3),
                  color: Colors.white,
                ),
                child: ctrl.state.value == ScanState.capturing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AgroColors.green,
                          strokeWidth: 3,
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            )),

            // Cambiar cámara (Funcionalidad añadida)
            _IconButton(
              icon: Icons.flip_camera_ios_outlined,
              onTap: () async {
                await ctrl.toggleCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Línea de escaneo animada ─────────────────────────────────────────────────

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 8, end: 224).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: _anim.value,
        left: 8,
        right: 8,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AgroColors.yellow.withOpacity(0.9),
                Colors.transparent,
              ],
            ),
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

// ─── Botón icono circular ─────────────────────────────────────────────────────

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
          border: Border.all(
              color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}