import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/utils/pose_math.dart';

// Defines the state of the exercise
enum ExerciseState {
  up,
  down,
  neutral, // Starting position
}

class ExerciseCounter {
  // --- Configuration ---

  // Thresholds for the "Overhead Press" (in degrees)
  // Arm is considered "up" when elbow angle is > 160 degrees
  final double _upAngleThreshold = 160.0;
  // Arm is considered "down" when elbow angle is < 70 degrees
  final double _downAngleThreshold = 70.0;
  // How confident ML Kit needs to be about the joint's position
  final double _landmarkConfidenceThreshold = 0.5;

  // --- State Variables ---

  // The current state of the exercise
  ExerciseState _state = ExerciseState.neutral;

  // Notifier to send the rep count back to the UI
  // We use ValueNotifier so the UI can just "listen" for changes
  final ValueNotifier<int> repNotifier = ValueNotifier(0);

  /// Processes the detected pose to update the rep count.
  void processPose(Pose pose) {
    try {
      // 1. Get all the landmarks we need
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      // 2. Check if all landmarks are visible and trustworthy
      if (leftShoulder == null ||
          leftElbow == null ||
          leftWrist == null ||
          rightShoulder == null ||
          rightElbow == null ||
          rightWrist == null) {
        // If any landmark is missing, we can't calculate
        return;
      }

      // Check confidence (likelihood)
      if (leftShoulder.likelihood < _landmarkConfidenceThreshold ||
          leftElbow.likelihood < _landmarkConfidenceThreshold ||
          leftWrist.likelihood < _landmarkConfidenceThreshold ||
          rightShoulder.likelihood < _landmarkConfidenceThreshold ||
          rightElbow.likelihood < _landmarkConfidenceThreshold ||
          rightWrist.likelihood < _landmarkConfidenceThreshold) {
        // If not confident, don't process this frame
        return;
      }

      // 3. Calculate the angles for both elbows
      final double leftElbowAngle =
          PoseMath.getAngle(leftShoulder, leftElbow, leftWrist);
      final double rightElbowAngle =
          PoseMath.getAngle(rightShoulder, rightElbow, rightWrist);

      // --- 4. The State Machine Logic ---

      // Check if both arms are in the "UP" position
      if (leftElbowAngle > _upAngleThreshold &&
          rightElbowAngle > _upAngleThreshold) {
        // If we were previously "down" or "neutral", this completes a rep.
        if (_state == ExerciseState.down || _state == ExerciseState.neutral) {
          _state = ExerciseState.up;
          // Increment the counter and notify listeners
          repNotifier.value++;
        }
        // If we are already "up", do nothing (prevents double counting)
      }
      // Check if both arms are in the "DOWN" position
      else if (leftElbowAngle < _downAngleThreshold &&
          rightElbowAngle < _downAngleThreshold) {
        // If we were previously "up", this means we are ready for the next rep.
        if (_state == ExerciseState.up) {
          _state = ExerciseState.down;
        }
        // If we are already "down" or "neutral", do nothing.
      }
    } catch (e) {
      print('Error processing pose for counter: $e');
    }
  }

  /// Resets the counter and state.
  void reset() {
    repNotifier.value = 0;
    _state = ExerciseState.neutral;
  }

  /// Cleans up the notifier when done.
  void dispose() {
    repNotifier.dispose();
  }
}
