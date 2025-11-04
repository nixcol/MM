import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/exercise_counter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late PoseDetector poseDetector;
  late CameraController controller;

  late ExerciseCounter _exerciseCounter;

  // Pose detection variables
  bool _isProcessing = false;
  List<Pose> _poses = [];
  bool _isDetecting = false;
  bool _isRecording = false;

  // Orientation control
  bool _isLandscape = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _exerciseCounter = ExerciseCounter();
    // Find the back camera
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    controller = CameraController(backCamera, ResolutionPreset.high);
    poseDetector = PoseDetector(options: PoseDetectorOptions());
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _startImageStream();
    });
    _exerciseCounter.repNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startImageStream() {
    controller.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _isProcessing = true;
        _processCameraImage(image);
      }
    });
  }

  void _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final poses = await poseDetector.processImage(inputImage);

        // Only process poses if we are actively recording
        if (_isRecording && poses.isNotEmpty) {
          // Send the detected pose to our counter
          _exerciseCounter.processPose(poses.first);
        }

        if (mounted) {
          setState(() {
            _poses = poses;
            _isDetecting = poses.isNotEmpty;
          });
        }
      } else {
        print('Failed to convert camera image');
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Get the sensor orientation from the active controller's description
      final sensorOrientation = controller.description.sensorOrientation;

      InputImageRotation rotation;

      if (Platform.isIOS) {
        // iOS uses the raw value directly
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg;
      } else if (Platform.isAndroid) {
        // Android rotation is based on the sensor orientation
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation90deg;
      } else {
        // Default for other platforms
        rotation = InputImageRotation.rotation90deg;
      }

      // Determine the image format
      InputImageFormat format;
      if (Platform.isIOS) {
        // iOS default format
        format = InputImageFormat.bgra8888;
      } else {
        // Android default format
        format = InputImageFormat.nv21;
      }

      // Concatenate planes into a single byte list
      final bytes = _concatenatePlanes(image.planes);

      if (bytes.isEmpty) {
        print('Error: Byte buffer was empty.');
        return null;
      }

      // Create the InputImage from the bytes and metadata
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation, // Use the calculated rotation
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    controller.stopImageStream();
    controller.dispose();
    poseDetector.close();

    _exerciseCounter.dispose();

    // Reset to allow all orientations when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
          ),
        ),
      );
    }

    final Size rotatedPreviewSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera with proper aspect ratio
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          ),

          // Exercise-specific pose overlay (only when recording)
          if (_poses.isNotEmpty && _isRecording)
            Positioned.fill(
              child: CustomPaint(
                painter: ExercisePosePainter(_poses, rotatedPreviewSize),
              ),
            ),

          // Back button (top left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D4FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF00D4FF),
                  size: 24,
                ),
              ),
            ),
          ),

          // Camera switch button (top left, below back button)
          Positioned(
            top: MediaQuery.of(context).padding.top + 85,
            left: 20,
            child: GestureDetector(
              onTap: _switchCamera,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF39FF14), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39FF14).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isFrontCamera ? Icons.camera_rear : Icons.camera_front,
                  color: const Color(0xFF39FF14),
                  size: 24,
                ),
              ),
            ),
          ),

          // Rep counter (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF00D4FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_exerciseCounter.repNotifier.value}',
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Start/Stop recording button (bottom center)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : const Color(0xFF00D4FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                                ? Colors.red
                                : const Color(0xFF00D4FF))
                            .withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          // Recording status indicator (bottom left)
          if (_isRecording)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 50,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'RECORDING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Orientation toggle button (bottom right)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 50,
            right: 20,
            child: GestureDetector(
              onTap: _toggleOrientation,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isLandscape
                        ? const Color(0xFF39FF14)
                        : const Color(0xFF00D4FF),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isLandscape
                              ? const Color(0xFF39FF14)
                              : const Color(0xFF00D4FF))
                          .withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isLandscape
                      ? Icons.screen_lock_portrait
                      : Icons.screen_lock_landscape,
                  color: _isLandscape
                      ? const Color(0xFF39FF14)
                      : const Color(0xFF00D4FF),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        _exerciseCounter.reset();
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      // Set to landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Allow all orientations to prevent iOS restrictions
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _switchCamera() async {
    try {
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });

      print('Switching camera to: ${_isFrontCamera ? 'front' : 'back'}');

      // Stop current stream
      await controller.stopImageStream();
      await controller.dispose();

      // Find the appropriate camera
      final selectedCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (_isFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => cameras.first,
      );

      print('Selected camera: ${selectedCamera.lensDirection}');

      // Initialize new camera
      controller = CameraController(selectedCamera, ResolutionPreset.high);
      await controller.initialize();

      if (mounted) {
        setState(() {});
        _startImageStream();
      }
    } catch (e) {
      print('Error switching camera: $e');
      // If there's an error, revert the state
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    }
  }
}

// Exercise-specific pose painter (shows only relevant keypoints)
class ExercisePosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size previewSize;

  ExercisePosePainter(this.poses, this.previewSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF39FF14)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      // Only draw key exercise points (shoulders, elbows, wrists for push-ups)
      _drawExerciseKeypoints(canvas, pose, paint, size);
      _drawExerciseConnections(canvas, pose, linePaint, size);
    }
  }

  void _drawExerciseKeypoints(
      Canvas canvas, Pose pose, Paint paint, Size size) {
    // Key points for push-ups/upper body exercises
    final keyPoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];

    for (final pointType in keyPoints) {
      final landmark = pose.landmarks[pointType];
      if (landmark != null) {
        final point = _scalePoint(landmark.x, landmark.y, size);
        canvas.drawCircle(point, 8, paint);
      }
    }
  }

  void _drawExerciseConnections(
      Canvas canvas, Pose pose, Paint paint, Size size) {
    // Only draw arm connections for exercise tracking
    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    ];

    for (final connection in connections) {
      final startLandmark = pose.landmarks[connection[0]];
      final endLandmark = pose.landmarks[connection[1]];

      if (startLandmark != null && endLandmark != null) {
        final start = _scalePoint(startLandmark.x, startLandmark.y, size);
        final end = _scalePoint(endLandmark.x, endLandmark.y, size);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  Offset _scalePoint(double x, double y, Size size) {
    double scaleX, scaleY;
    double translateX = 0, translateY = 0;

    final previewSize = this.previewSize;
    final screenAspectRatio = size.width / size.height;
    final previewAspectRatio = previewSize.width / previewSize.height;

    if (previewAspectRatio > screenAspectRatio) {
      // Preview is wider than screen
      scaleY = size.height / previewSize.height;
      scaleX = scaleY;
      translateX = (size.width - (previewSize.width * scaleX)) / 2;
    } else {
      // Preview is taller than screen
      scaleX = size.width / previewSize.width;
      scaleY = scaleX;
      translateY = (size.height - (previewSize.height * scaleY)) / 2;
    }

    return Offset(
      (x * scaleX) + translateX,
      (y * scaleY) + translateY,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
