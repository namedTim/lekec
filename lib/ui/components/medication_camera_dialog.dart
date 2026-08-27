import 'dart:async';
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
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  _CapturePhase _phase = _CapturePhase.camera;
  String? _errorMessage;
  String _processingStep = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Determinate progress (0.0 -> 1.0) shown in the processing card. The quick
  // pre-flight phases occupy 0.0-0.10; the long AI extraction call animates
  // from 0.10 toward 0.95 (never reaching it before the result arrives), and
  // completion snaps it to 1.0.
  late AnimationController _progressController;
  double _progress = 0.0;

  // Expected average duration of extractMedicationInfo(). The bar decelerates
  // toward 0.95 over this window and stays capped there if the call runs long.
  static const Duration _extractExpectedDuration = Duration(milliseconds: 13000);
  static const double _extractStart = 0.10;
  static const double _extractCeiling = 0.95;

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
    _progressController = AnimationController(
      vsync: this,
      duration: _extractExpectedDuration,
    )..addListener(_onExtractProgressTick);
    _initializeCamera();
  }

  /// Maps the linear controller value through a decelerating curve so the bar
  /// eases toward [_extractCeiling] and slows as it approaches it.
  void _onExtractProgressTick() {
    if (!mounted) return;
    final eased = Curves.easeOut.transform(_progressController.value);
    final value = _extractStart + (_extractCeiling - _extractStart) * eased;
    setState(() => _progress = value.clamp(0.0, _extractCeiling));
  }

  void _setProgress(double value) {
    if (!mounted) return;
    setState(() => _progress = value.clamp(0.0, 1.0));
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

  /// Shows a transient error overlay, then returns to the camera so the user
  /// can retry.
  Future<void> _failTransiently(String message) async {
    _pulseController.stop();
    _progressController.stop();
    _progressController.reset();
    if (!mounted) return;
    setState(() {
      _phase = _CapturePhase.error;
      _errorMessage = message;
      _progress = 0.0;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _phase = _CapturePhase.camera;
        _errorMessage = null;
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final geminiService = GeminiMedicationService();

    try {
      // Phase 1: Capture
      final XFile image = await _cameraController!.takePicture();

      setState(() => _phase = _CapturePhase.captured);

      // Brief flash to confirm capture
      await Future.delayed(const Duration(milliseconds: 600));

      // Phase 2: Check internet
      setState(() {
        _phase = _CapturePhase.processing;
        _processingStep = 'Preverjam internetno povezavo...';
        _progress = 0.02;
      });
      _pulseController.repeat(reverse: true);

      try {
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        if (lookup.isEmpty || lookup.first.rawAddress.isEmpty) {
          throw const SocketException('No internet');
        }
      } on SocketException {
        await _failTransiently(
          'Ni internetne povezave.\nAI zajem potrebuje internet.',
        );
        return;
      } on TimeoutException {
        await _failTransiently(
          'Ni internetne povezave.\nAI zajem potrebuje internet.',
        );
        return;
      }

      // Phase 2b: Confirm the AI service is actually reachable before we
      // commit to uploading the photo (otherwise a down server hangs until the
      // long extract timeout). Fails fast with a clear warning.
      if (mounted) {
        setState(() {
          _processingStep = 'Preverjam dosegljivost storitve...';
          _progress = 0.05;
        });
      }
      final reachable = await geminiService.isServiceReachable();
      if (!reachable) {
        await _failTransiently(
          'Storitev trenutno ni dosegljiva.\nPoskusite znova kasneje.',
        );
        return;
      }

      // Phase 3: Prepare image
      if (mounted) {
        setState(() {
          _processingStep = 'Pripravljam sliko...';
          _progress = 0.08;
        });
      }
      await Future.delayed(const Duration(milliseconds: 300));

      final File imageFile = File(image.path);

      // Phase 4: AI analysis
      if (mounted) {
        setState(() {
          _processingStep = 'Pošiljam AI-ju za analizo...';
          _progress = _extractStart;
        });
      }
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() => _processingStep = 'AI analizira zdravilo...');
      }

      // Drive the determinate bar from _extractStart toward _extractCeiling
      // over the expected duration while we await the long extraction call.
      _progressController
        ..reset()
        ..forward();

      final result = await geminiService.extractMedicationInfo(imageFile);

      // Result arrived: stop the timed fill and complete the bar.
      _progressController.stop();
      _setProgress(1.0);

      if (mounted) {
        setState(() => _processingStep = 'Izpolnjujem podatke...');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      _pulseController.stop();

      // Phase 3: Done
      setState(() => _phase = _CapturePhase.done);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      await _failTransiently('Ni uspelo. Poskusite znova.');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController
      ..removeListener(_onExtractProgressTick)
      ..dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.55,
        color: colors.surface,
        child: Stack(
          children: [
            // Camera / Status area - full height
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera preview or captured image
                  _buildPreviewArea(colors),

                  // Overlay for captured/processing/done states
                  if (_phase == _CapturePhase.captured)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Center(
                        child: Icon(
                          Symbols.check_circle,
                          size: 72,
                          color: colors.primary,
                        ),
                      ),
                    ),

                  if (_phase == _CapturePhase.processing)
                    _ScrimCard(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.auto_awesome,
                                size: 44,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Analiziram...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _processingStep,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 160,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: _progress,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                builder: (context, value, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LinearProgressIndicator(
                                      value: value,
                                      borderRadius: BorderRadius.circular(4),
                                      color: colors.primary,
                                      backgroundColor:
                                          colors.surfaceContainerHighest,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(value * 100).round()} %',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_phase == _CapturePhase.done)
                    _ScrimCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Symbols.check_circle,
                              size: 52,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Zaključeno!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_phase == _CapturePhase.error && _errorMessage != null)
                    _ScrimCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Symbols.warning,
                              size: 48,
                              color: colors.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Header at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
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
                      icon: const Icon(Symbols.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Capture button - centered in bottom half
            if (_phase == _CapturePhase.camera)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.55 * 0.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Usmerite kamero na škatlo ali nalepko',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _captureAndProcess,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Symbols.photo_camera,
                          size: 30,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme colors) {
    if (!_isInitialized || _cameraController == null) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
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

/// A dark scrim over the camera feed with a centered themed card, used for the
/// processing / done / error states so they read consistently in light & dark.
class _ScrimCard extends StatelessWidget {
  const _ScrimCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}
