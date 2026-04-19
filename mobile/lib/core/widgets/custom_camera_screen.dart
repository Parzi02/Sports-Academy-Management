import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isReady = false;
  XFile? _capturedFile;

  int _currentCameraIndex = 0;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      
      // Default to front camera
      _currentCameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _setCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _setCamera(int index) async {
    if (_cameras.isEmpty) return;
    
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _isReady = true);
  }

  void _flipCamera() {
    if (_cameras.isEmpty) return;
    setState(() => _isReady = false);
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _setCamera(_currentCameraIndex);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile picture = await _controller!.takePicture();
      if (!mounted) return;

      setState(() => _isProcessingImage = true);

      // Read image
      final bytes = await picture.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      canvas.drawImage(image, Offset.zero, Paint());

      // Draw timestamp
      String dateText = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String timeText = DateFormat('HH:mm:ss').format(DateTime.now());

      final textSpan = TextSpan(
        text: '$dateText\n$timeText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64, // Large font for camera resolution
          fontWeight: FontWeight.bold,
          height: 1.2,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(4, 4)),
            Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(2, 2)),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      // Position bottom right
      final x = image.width.toDouble() - textPainter.width - 40;
      final y = image.height.toDouble() - textPainter.height - 40;

      textPainter.paint(canvas, Offset(x, y));

      final ui.Picture p = recorder.endRecording();
      final ui.Image finalImage = await p.toImage(image.width, image.height);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final newPath = picture.path.replaceAll('.jpg', '_stamped.png');
        final file = File(newPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        setState(() {
          _capturedFile = XFile(newPath);
          _isProcessingImage = false;
        });
      } else {
        setState(() {
          _capturedFile = picture;
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  void _retake() {
    setState(() => _capturedFile = null);
  }

  void _confirm() {
    if (_capturedFile != null) {
      Navigator.of(context).pop(File(_capturedFile!.path));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera or Photo Preview
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / _controller!.value.aspectRatio,
                  child: _capturedFile != null 
                      ? Image.file(File(_capturedFile!.path), fit: BoxFit.cover)
                      : CameraPreview(_controller!),
                ),
              ),
            ),
          ),
          
          // Back button (only shown when not previewing)
          if (_capturedFile == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            
          // Flip camera button (REMOVED FROM TOP)
          
          if (_isProcessingImage)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          
          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: _capturedFile != null 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _retake,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retake", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Confirm Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _confirm,
                        icon: const Icon(Icons.check),
                        label: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shutter Button
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Flip Camera Button to the right
                    if (_cameras.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                          onPressed: _flipCamera,
                        ),
                      ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
