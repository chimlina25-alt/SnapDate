import 'package:flutter/material.dart';
import 'resetss_view.dart';

class VerificationView extends StatelessWidget {
  final String email;

  // We pass the email from the previous screen to show a personalized message
  const VerificationView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFA3D2CA),
      body: Stack(
        children: [
          // Top Logo Section matching your theme
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.35,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0C0C0).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Text(
                  'SnapDate',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),

          // Message Card
          Positioned(
            top: screenSize.height * 0.30,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(45),
                  topRight: Radius.circular(45),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 90,
                      color: Color(0xFFE8B4B8),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Reset Email Sent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "We sent a password reset link to $email. After you finish changing your password from that email, come back here to continue.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black45,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),

                    // The "Action Done" Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Takes the user directly to the success completion view
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResetSuccessView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6A2A8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "I've Reset My Password",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
