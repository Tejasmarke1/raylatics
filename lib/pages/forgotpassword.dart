import 'package:flutter/material.dart';
import 'dart:async';

// Enum to manage the current step of the forgot password process
enum ForgotPasswordStep {
  enterEmail,
  enterOtp,
  resetPassword,
  confirmation,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // The current step, starting with asking for the email
  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;

  // Controllers for the input fields
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // This method is called when the final "Reset" button is pressed
  void _submitAndShowConfirmation() {
    setState(() {
      _currentStep = ForgotPasswordStep.confirmation;
    });

    // After 3 seconds, automatically navigate back to the previous screen (LoginScreen)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          // Use a switch statement to build the UI for the current step
          child: switch (_currentStep) {
            ForgotPasswordStep.enterEmail => _buildEnterEmailStep(),
            ForgotPasswordStep.enterOtp => _buildEnterOtpStep(),
            ForgotPasswordStep.resetPassword => _buildResetPasswordStep(),
            ForgotPasswordStep.confirmation => _buildConfirmationStep(),
          },
        ),
      ),
    );
  }

  // UI for Step 1: Entering the Email Address
  Widget _buildEnterEmailStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildTextField(controller: _emailController, hint: 'Email Address'),
        const SizedBox(height: 24),
        _buildButtonRow(
          actionText: 'OTP',
          onActionPressed: () => setState(() => _currentStep = ForgotPasswordStep.enterOtp),
        ),
      ],
    );
  }

  // UI for Step 2: Verifying the OTP
  Widget _buildEnterOtpStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildTextField(controller: _otpController, hint: 'OTP', inputType: TextInputType.number),
        const SizedBox(height: 24),
        _buildButtonRow(
          actionText: 'Verify',
          onActionPressed: () => setState(() => _currentStep = ForgotPasswordStep.resetPassword),
        ),
      ],
    );
  }

  // UI for Step 3: Entering the New Password
  Widget _buildResetPasswordStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildTextField(controller: _newPasswordController, hint: 'New Password', isPassword: true),
        const SizedBox(height: 24),
        _buildButtonRow(
          actionText: 'Reset',
          onActionPressed: _submitAndShowConfirmation,
        ),
      ],
    );
  }

  // UI for Step 4: Confirmation Message
  Widget _buildConfirmationStep() {
    return const Center(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, color: Colors.black, size: 80),
        SizedBox(height: 24),
        Text(
          'Password Reset Successfully!',
          textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        Text(
          'Back to Login',
          textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
      ),
    );
  }

  // --- Reusable Helper Widgets ---

  // Header with Logo and Title, used in the first 3 steps
  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6A359C), Color(0xFFF85F43)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'RAYLYTICS',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Forgot Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Text field used across the flow
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // Button row with "Cancel" and a dynamic action button
  Widget _buildButtonRow({required String actionText, required VoidCallback onActionPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: onActionPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333742),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}