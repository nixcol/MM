import 'package:flutter/material.dart';
import 'dart:ui';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfe4100).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFfe4100),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Color(0xFFfe4100),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'SmartFit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Welcome message
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Guest!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                // // Progress card
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(24),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //       colors: [
                //         const Color(0xFF00D4FF).withOpacity(0.1),
                //         const Color(0xFF39FF14).withOpacity(0.1),
                //       ],
                //     ),
                //     borderRadius: BorderRadius.circular(20),
                //     border: Border.all(
                //       color: const Color(0xFF00D4FF).withOpacity(0.3),
                //       width: 1,
                //     ),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           const Icon(
                //             Icons.trending_up,
                //             color: Color(0xFF39FF14),
                //             size: 24,
                //           ),
                //           const SizedBox(width: 12),
                //           const Text(
                //             'Your Progress',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 20,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //       const SizedBox(height: 16),
                //       const Text(
                //         'Ready to start your fitness journey!',
                //         style: TextStyle(
                //           color: Colors.white70,
                //           fontSize: 16,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                //const SizedBox(height: 40),

                // Choose exercise section
                const Text(
                  'Choose Your Exercise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Exercise cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildExerciseCard(
                        context,
                        '💪',
                        'Push Ups',
                        'Upper body strength',
                        const Color(0xFF00D4FF),
                      ),
                      _buildExerciseCard(
                        context,
                        '🏃‍♂️',
                        'Squats',
                        'Lower body power',
                        const Color(0xFF39FF14),
                      ),
                      _buildExerciseCard(
                        context,
                        '🏋️‍♀️',
                        'Planks',
                        'Core strength',
                        const Color(0xFFE056FD),
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

  Widget _buildExerciseCard(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to camera screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
