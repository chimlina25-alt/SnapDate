import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../main_layout.dart';

class VerificationView extends StatefulWidget {
  const VerificationView({super.key});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkEmailVerified();
    });
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      timer?.cancel();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,

          MaterialPageRoute(builder: (_) => const MainLayout()),

          (route) => false,
        );
      }
    }
  }

  Future resendEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.email, size: 80),

              const SizedBox(height: 20),

              const Text(
                "Verification Email Sent",

                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                "Please open your email and click the verification link",
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: resendEmail,

                child: const Text("Resend Email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
