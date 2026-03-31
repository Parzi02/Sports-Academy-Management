import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Placeholder)
          Image.asset(
            'assets/images/get_started.jpg',
            fit: BoxFit.cover,
          ),
          // Purple Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primary,
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACADEMY\nMANAGEMENT',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Expert Training. Real Progress. Track your sports journey with ease and precision.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => context.go('/auth/role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('GET STARTED'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
