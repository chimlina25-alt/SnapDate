import 'package:flutter/material.dart';
import 'resetss_view.dart';

class CreateNewPasswordView extends StatefulWidget {
  const CreateNewPasswordView({super.key});

  @override
  State<CreateNewPasswordView> createState() => _CreateNewPasswordViewState();
}

class _CreateNewPasswordViewState extends State<CreateNewPasswordView> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFA3D2CA), // Mint Teal
      body: Stack(
        children: [
          // 1. Top Section: Camera & Logo
          _buildTopLogo(screenSize),

          // 2. White Container Card
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 30, 32, 24),
                child: Column(
                  children: [
                    // Pink Lock Icon
                    const Icon(Icons.lock_reset_rounded, size: 80, color: Color(0xFFE8B4B8)),
                    const SizedBox(height: 10),
                    const Text(
                      'Create new password',
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('Enter your new password below', style: TextStyle(color: Colors.black45)),
                    const SizedBox(height: 30),

                    // Inputs
                    _buildLabel('New password'),
                    _buildTextField(_passController, 'Create a strong password', obscure: true),
                    const SizedBox(height: 20),
                    _buildLabel('Confirm new password'),
                    _buildTextField(_confirmController, 'Confirm your password', obscure: true),
                    
                    const SizedBox(height: 40),

                    // Reset Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetSuccessView()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6A2A8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Reset password', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLogo(Size size) {
    return Positioned(
      top: 0, left: 0, right: 0, height: size.height * 0.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 40, right: size.width * 0.18,
            child: Image.asset('assets/welcome.png', width: 130, height: 130, fit: BoxFit.contain),
          ),
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
    );
  }

  Widget _buildLabel(String text) {
    return Align(alignment: Alignment.centerLeft, child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    ));
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}