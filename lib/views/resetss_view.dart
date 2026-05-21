import 'package:flutter/material.dart';
import 'signin_view.dart';

class ResetSuccessView extends StatelessWidget {
  const ResetSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFA3D2CA),
      body: Stack(
        children: [
          // Top Logo Section
          Positioned(
            top: 0, left: 0, right: 0, height: screenSize.height * 0.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                
                Positioned(
                  top: 95,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0C0C0).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text('SnapDate', style: TextStyle(fontFamily: 'Georgia', fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  ),
                ),
              ],
            ),
          ),

          // Success Card
          Positioned(
            top: screenSize.height * 0.30,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.check_circle_outline_rounded, size: 90, color: Color(0xFFD6A2A8)),
                    const SizedBox(height: 20),
                    const Text(
                      'Password reset successful',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Your password has been updated. You can now sign in with your new password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, height: 1.5),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Goes back to Sign In and clears navigation history
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInView()), (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6A2A8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Return', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
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