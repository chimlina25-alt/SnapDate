import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'resetss_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() =>
      _ForgotPasswordViewState();
}

class _ForgotPasswordViewState
    extends State<ForgotPasswordView> {

  final _emailController =
      TextEditingController();

  bool _isLoading = false;

  Future<void> _resetPassword() async {

    if (_emailController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Please enter email"),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {

      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: _emailController.text
            .trim(),
      );

      if (mounted) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ResetSuccessView(),
          ),
        );

      }

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                "Failed to send email",
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          _isLoading = false;
        });

      }

    }

  }

  @override
  Widget build(BuildContext context) {

    final screenSize =
        MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          const Color(0xFFA3D2CA),

      body: Stack(
        children: [

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                screenSize.height * 0.35,
            child: Center(
              child: _buildLogoBanner(),
            ),
          ),

          Positioned(
            top:
                screenSize.height * 0.30,
            left: 0,
            right: 0,
            bottom: 0,

            child: Container(

              decoration:
                  const BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.only(

                  topLeft:
                      Radius.circular(
                          45),

                  topRight:
                      Radius.circular(
                          45),

                ),

              ),

              child:
                  SingleChildScrollView(

                padding:
                    const EdgeInsets
                        .fromLTRB(
                  32,
                  35,
                  32,
                  24,
                ),

                child: Column(

                  children: [

                    const Icon(
                      Icons
                          .mail_outline_rounded,
                      size: 80,
                      color: Color(
                          0xFFE8B4B8),
                    ),

                    const SizedBox(
                        height: 16),

                    const Text(
                      'Forgot your password?',
                      style: TextStyle(
                        fontFamily:
                            'Georgia',
                        fontSize: 24,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                        height: 12),

                    const Text(

                      'Enter your email and we will send a reset link.',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Colors.black45,
                      ),

                    ),

                    const SizedBox(
                        height: 35),

                    Align(
                      alignment:
                          Alignment
                              .centerLeft,

                      child:
                          _buildLabel(
                              "Email address"),

                    ),

                    _buildTextField(
                      _emailController,
                      "Enter your email",
                    ),

                    const SizedBox(
                        height: 35),

                    SizedBox(

                      width:
                          double.infinity,

                      height: 50,

                      child:
                          ElevatedButton(

                        onPressed:
                            _isLoading
                                ? null
                                : _resetPassword,

                        style:
                            ElevatedButton
                                .styleFrom(

                          backgroundColor:
                              const Color(
                                  0xFFD6A2A8),

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius.circular(
                                    12),

                          ),

                        ),

                        child: _isLoading

                            ? const CircularProgressIndicator(
                                color:
                                    Colors.white)

                            : const Text(

                                'Send Reset Email',

                                style:
                                    TextStyle(

                                  color:
                                      Colors.black87,

                                  fontWeight:
                                      FontWeight.bold,

                                ),

                              ),

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

  Widget _buildLogoBanner() {

    return Container(

      padding:
          const EdgeInsets.symmetric(

        horizontal: 44,
        vertical: 14,

      ),

      decoration: BoxDecoration(

        color:
            const Color(0xFFC0C0C0)
                .withOpacity(0.85),

        borderRadius:
            BorderRadius.circular(
                50),

      ),

      child: const Text(

        'SnapDate',

        style: TextStyle(

          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight:
              FontWeight.bold,
          fontStyle:
              FontStyle.italic,

        ),

      ),

    );

  }

  Widget _buildLabel(
      String text) {

    return Padding(

      padding:
          const EdgeInsets.only(
              bottom: 6),

      child: Text(

        text,

        style: const TextStyle(

          fontWeight:
              FontWeight.w500,

        ),

      ),

    );

  }

  Widget _buildTextField(

    TextEditingController controller,
    String hint,

  ) {

    return TextField(

      controller: controller,

      decoration:
          InputDecoration(

        hintText: hint,

        contentPadding:
            const EdgeInsets
                .symmetric(

          horizontal: 16,
          vertical: 14,

        ),

        border:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(
                  12),

        ),

      ),

    );

  }

}