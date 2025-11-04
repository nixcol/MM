import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMath {
  /// Calculates the angle between three 3D points.
  ///
  /// [p1] - The first point (e.g., shoulder)
  /// [p2] - The second point, which is the vertex (e.g., elbow)
  /// [p3] - The third point (e.g., wrist)
  ///
  /// Returns the angle in degrees.
  static double getAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    // Calculate vectors
    final v1x = p1.x - p2.x;
    final v1y = p1.y - p2.y;
    final v1z = p1.z - p2.z;

    final v2x = p3.x - p2.x;
    final v2y = p3.y - p2.y;
    final v2z = p3.z - p2.z;

    // Calculate dot product
    final dotProduct = (v1x * v2x) + (v1y * v2y) + (v1z * v2z);

    // Calculate magnitudes (lengths) of the vectors
    final mag1 = sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
    final mag2 = sqrt(v2x * v2x + v2y * v2y + v2z * v2z);

    // Prevent division by zero
    if (mag1 == 0 || mag2 == 0) {
      return 0.0;
    }

    // Calculate the cosine of the angle
    var cosTheta = dotProduct / (mag1 * mag2);

    // Clamp the value to [-1, 1] to avoid domain errors for acos
    cosTheta = cosTheta.clamp(-1.0, 1.0);

    // Calculate the angle in radians
    final angleInRadians = acos(cosTheta);

    // Convert radians to degrees
    final angleInDegrees = angleInRadians * (180 / pi);

    return angleInDegrees;
  }
}