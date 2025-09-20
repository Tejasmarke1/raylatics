import 'package:flutter/material.dart';
import 'dart:async'; // Required for the Timer
import 'login.dart'; // Import your login screen

class LaunchAppScreen extends StatefulWidget {
  const LaunchAppScreen({super.key});

  @override
  State<LaunchAppScreen> createState() => _LaunchAppScreenState();
}

class _LaunchAppScreenState extends State<LaunchAppScreen> {

  @override
  void initState() {
    super.initState();
    // Use Future.delayed for a cleaner, one-time delay
    Future.delayed(const Duration(seconds: 2), () {
      // Ensure the widget is still mounted before navigating
      if (mounted) {
        // Use pushReplacement to prevent the user from going back to the splash screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Your UI code from before remains exactly the same
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF6A359C), // Custom Purple
                    Color(0xFFF85F43), // Custom Orange
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: const Text(
                  'RAYLYTICS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Raylytics predicts solar power generation in real time for smarter energy decisions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFD8C7E8), // Light Purple
                  strokeWidth: 5.0,
                ),
              ),
              const Spacer(flex: 3),
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  '© 2025 Raylytics. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}