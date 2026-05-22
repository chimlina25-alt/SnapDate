import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CameraMainView extends StatefulWidget {
  const CameraMainView({super.key});

  @override
  State<CameraMainView> createState() => _CameraMainViewState();
}

class _CameraMainViewState extends State<CameraMainView> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _triggerCameraShutter(ImageSource targetSource) async {
    setState(() => _isProcessing = true);
    try {
      final XFile? takenPhoto = await _picker.pickImage(
        source: targetSource, 
        imageQuality: 70
      );

      if (takenPhoto != null) {
        // 1. Write file out directly into the native System Photo Gallery Roll
        await Gal.putImage(takenPhoto.path);

        // 2. Encode image to Base64 to safely store as string inside Firestore text collections
        final bytes = await File(takenPhoto.path).readAsBytes();
        final String base64ImageString = "data:image/png;base64,${base64Encode(bytes)}";

        final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // 3. Register memory transaction inside your Firestore date collection
        await FirebaseFirestore.instance.collection('users').doc(uid).collection('memories').add({
          'imageUrl': base64ImageString,
          'timestamp': FieldValue.serverTimestamp(),
          'dateGroup': todayKey,
          'isFavorite': false,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memory captured! Saved to Gallery Roll and Calendar view.'))
          );
        }
      }
    } catch (e) {
      debugPrint("Camera input capturing exception error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isProcessing 
          ? const CircularProgressIndicator(color: Color(0xFFD6A2A8))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_enhance_outlined, size: 80, color: Colors.white24),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A2A8), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("TAKE LIVE PHOTO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _triggerCameraShutter(ImageSource.camera),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  icon: const Icon(Icons.photo_library, color: Colors.white60),
                  label: const Text("IMPORT FROM GALLERY", style: TextStyle(color: Colors.white60)),
                  onPressed: () => _triggerCameraShutter(ImageSource.gallery),
                )
              ],
            ),
      ),
    );
  }
}