import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../services/gemini_medication_service.dart';

class MedicationCameraDialog extends StatefulWidget {
  const MedicationCameraDialog({super.key});

  @override
  State<MedicationCameraDialog> createState() => _MedicationCameraDialogState();
}

enum _CapturePhase { camera, captured, processing, done, error }

class _MedicationCameraDialogState extends State<MedicationCameraDialog>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  _CapturePhase _phase = _CapturePhase.camera;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _phase = _CapturePhase.error;
          _errorMessage = 'Kamera ni na voljo';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() {
        _phase = _CapturePhase.error;
        _errorMessage = 'Napaka kamere';
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Phase 1: Capture
      final XFile image = await _cameraController!.takePicture();

      setState(() => _phase = _CapturePhase.captured);

      // Brief flash to confirm capture
      await Future.delayed(const Duration(milliseconds: 600));

      // Phase 2: Processing
      setState(() {
        _phase = _CapturePhase.processing;
      });
      _pulseController.repeat(reverse: true);

      final File imageFile = File(image.path);
      final geminiService = GeminiMedicationService();
      final result = await geminiService.extractMedicationInfo(imageFile);

      _pulseController.stop();

      // Phase 3: Done
      setState(() => _phase = _CapturePhase.done);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      _pulseController.stop();
      setState(() {
        _phase = _CapturePhase.error;
        _errorMessage = 'Ni uspelo. Poskusite znova.';
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _phase = _CapturePhase.camera;
          _errorMessage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.55,
        color: Colors.black,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.auto_awesome,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI zajem',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close, color: Colors.white70),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),

            // Camera / Status area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera preview or captured image
                  _buildPreviewArea(colors),

                  // Overlay for captured/processing/done states
                  if (_phase == _CapturePhase.captured)
                    Container(
                      color: Colors.white.withOpacity(0.9),
                      child: Center(
                        child: Icon(
                          Symbols.check_circle,
                          size: 72,
                          color: Colors.green.shade400,
                        ),
                      ),
                    ),

                  if (_phase == _CapturePhase.processing)
                    Container(
                      color: Colors.black.withOpacity(0.75),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Symbols.auto_awesome,
                                  size: 48,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Analiziram...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 160,
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(4),
                                  color: colors.primary,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (_phase == _CapturePhase.done)
                    Container(
                      color: Colors.black.withOpacity(0.75),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Symbols.check_circle,
                                size: 56,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Zaključeno!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_phase == _CapturePhase.error && _errorMessage != null)
                    Container(
                      color: Colors.black.withOpacity(0.75),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.error, size: 56, color: colors.error),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.black,
              child: _phase == _CapturePhase.camera
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Usmerite kamero na škatlo ali nalepko',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _captureAndProcess,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Symbols.photo_camera,
                              size: 30,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(height: 68),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme colors) {
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final cameraAspect = _cameraController!.value.aspectRatio; // height/width
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1,
            height: cameraAspect,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }
}
