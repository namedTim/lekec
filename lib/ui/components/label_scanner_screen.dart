import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as developer;

class LabelScannerScreen extends StatefulWidget {
  const LabelScannerScreen({super.key});

  @override
  State<LabelScannerScreen> createState() => _LabelScannerScreenState();
}

class _LabelScannerScreenState extends State<LabelScannerScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Ni razpoložljive kamere');
        return;
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      developer.log('Camera init error: $e', name: 'LabelScanner');
      if (mounted) {
        setState(() => _error = 'Napaka pri inicializaciji kamere');
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text.trim();
      developer.log('Recognized text: $fullText', name: 'LabelScanner');

      if (fullText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Besedilo ni bilo zaznano. Poskusite znova.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Extract the medication name - typically the first meaningful line
      final medName = _extractMedicationName(recognizedText);

      if (mounted) {
        Navigator.of(context).pop(medName);
      }
    } catch (e) {
      developer.log('Recognition error: $e', name: 'LabelScanner');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Extract the most likely medication name from recognized text.
  /// Looks for the largest/most prominent text block which is typically the med name on labels.
  String _extractMedicationName(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return '';

    // Strategy: medication name on labels is usually the largest text.
    // Find the block with the tallest bounding box (biggest font).
    TextBlock? largestBlock;
    double maxHeight = 0;

    for (final block in recognizedText.blocks) {
      final height = block.boundingBox.height;
      if (height > maxHeight) {
        maxHeight = height;
        largestBlock = block;
      }
    }

    if (largestBlock != null) {
      // Clean up the text - take first line if multi-line
      final text = largestBlock.text.trim();
      final lines = text.split('\n');
      // Return the first non-empty line, cleaned up
      for (final line in lines) {
        final cleaned = line.trim();
        if (cleaned.isNotEmpty && cleaned.length > 1) {
          // Remove trailing dosage info like "500 mg", "20 mg" etc.
          // But keep the medication name intact
          return _cleanMedName(cleaned);
        }
      }
      return text;
    }

    // Fallback: return first block's text
    return recognizedText.blocks.first.text.trim().split('\n').first.trim();
  }

  String _cleanMedName(String raw) {
    // Remove common suffixes that are not part of the name
    // but keep things like "Aspirin 500mg" as is since user might want dosage info
    return raw.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: const Text(
          'Skeniraj nalepko',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.error, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: colors.error, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // Camera preview - full screen
                Positioned.fill(child: CameraPreview(_cameraController!)),

                // Dark overlay with cut-out + border, using LayoutBuilder for correct sizing
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bodyWidth = constraints.maxWidth;
                      final bodyHeight = constraints.maxHeight;
                      final labelWidth = bodyWidth * 0.85;
                      const labelHeight = 80.0;
                      final labelLeft = (bodyWidth - labelWidth) / 2;
                      final labelTop = (bodyHeight - labelHeight) / 2;
                      final labelRect = Rect.fromLTWH(
                        labelLeft,
                        labelTop,
                        labelWidth,
                        labelHeight,
                      );

                      return CustomPaint(
                        size: Size(bodyWidth, bodyHeight),
                        painter: _LabelOverlayPainter(labelRect: labelRect),
                      );
                    },
                  ),
                ),

                // Label frame border (uses Center which also centers within body)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: size.width * 0.85,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Instruction text
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.25,
                  child: Text(
                    'Poravnajte ime zdravila v okvir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Capture button - centered in bottom half of screen
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.of(context).size.height * 0.5, // bottom half
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _captureAndRecognize,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isProcessing ? Colors.grey : Colors.white,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 4,
                          ),
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                Symbols.photo_camera,
                                size: 32,
                                color: Colors.black,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Paints a semi-transparent dark overlay with a cut-out for the label area
class _LabelOverlayPainter extends CustomPainter {
  final Rect labelRect;

  _LabelOverlayPainter({required this.labelRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    // Draw full overlay
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(labelRect, const Radius.circular(12));

    // Create path with hole
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(rrect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LabelOverlayPainter oldDelegate) {
    return oldDelegate.labelRect != labelRect;
  }
}
