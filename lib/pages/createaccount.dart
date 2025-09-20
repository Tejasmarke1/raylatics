import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Added for the timer
import 'login.dart'; // Added for navigation back to login
import '../services/auth_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // Controllers to manage the text in the TextFormFields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variable to track the checkbox value
  bool _termsAccepted = false;

  @override
  void dispose() {
    // Clean up the controllers when the widget is removed from the widget tree
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: LayoutBuilder(
            // Use LayoutBuilder to get constraints
            builder: (context, constraints) {
              return SingleChildScrollView(
                // Prevents overflow when keyboard appears
                child: ConstrainedBox(
                  // Ensure the column takes at least the screen height
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    // Make column height fit its content or screen height
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center vertically
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        // Logo with Gradient
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF6A359C), // Custom Purple
                                  Color(0xFFF85F43), // Custom Orange
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                          child: const Text(
                            'RAYLYTICS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline
                        const Text(
                          'Raylytics predicts solar power generation in real time for smarter energy decisions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Input Fields
                        _buildTextField(
                          controller: _firstNameController,
                          hint: 'First Name',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _lastNameController,
                          hint: 'Last Name',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email Address',
                          inputType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          isPassword: true,
                        ),
                        const SizedBox(height: 10),

                        // Terms & Conditions Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (bool? value) {
                                setState(() {
                                  _termsAccepted = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF6A359C),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontFamily: 'Sans-serif',
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions.',
                                      style: const TextStyle(
                                        color: Color(0xFF6A359C),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              // TODO: Show a dialog or navigate to the Terms & Conditions page
                                              print(
                                                'Terms & Conditions tapped!',
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sign Up Button
                        ElevatedButton(
                          // Button is disabled if terms are not accepted
                          onPressed:
                              _termsAccepted
                                  ? () async {
                                    final _authService = AuthService();

                                    try {
                                      await _authService.signUp(
                                        firstName:
                                            _firstNameController.text.trim(),
                                        lastName:
                                            _lastNameController.text.trim(),
                                        email: _emailController.text.trim(),
                                        password:
                                            _passwordController.text.trim(),
                                      );

                                      // If success → go to confirmation screen
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const AccountCreatedConfirmationScreen(),
                                        ),
                                      );
                                    } catch (e) {
                                      // Show error message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                  : null,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF333742,
                            ), // Dark grey
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper method to reduce code duplication for TextFormFields
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF6A359C)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
      ),
    );
  }
}

// +++ ADDED THIS NEW WIDGET FOR THE CONFIRMATION SCREEN +++

class AccountCreatedConfirmationScreen extends StatefulWidget {
  const AccountCreatedConfirmationScreen({super.key});

  @override
  State<AccountCreatedConfirmationScreen> createState() =>
      _AccountCreatedConfirmationScreenState();
}

class _AccountCreatedConfirmationScreenState
    extends State<AccountCreatedConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // After 3 seconds, redirect to the Login Screen
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // This clears the entire navigation stack and pushes the LoginScreen,
        // so the user cannot go back to the sign-up flow.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.black,
              size: 100,
            ),
            SizedBox(height: 24),
            Text(
              'Your Account Created Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Back to Login.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
