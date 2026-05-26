import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../service/user_service.dart';
import '../utils/app_image.dart';

class EditProfileView extends StatefulWidget {
  final String currentUsername;
  final String currentAvatar;
  final String currentBio;

  const EditProfileView({
    super.key,
    required this.currentUsername,
    required this.currentAvatar,
    this.currentBio = '',
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _userController;
  late TextEditingController _bioController;
  String _avatarUrl = "";
  XFile? _avatarFile;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.currentUsername);
    _bioController = TextEditingController(text: widget.currentBio);
    _avatarUrl = widget.currentAvatar;
  }

  Future<void> _pickAvatarImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose Photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final XFile? selected = await _picker.pickImage(
      source: source,
      imageQuality: 60,
    );
    if (selected != null) {
      setState(() {
        _avatarFile = selected;
      });
    }
  }

  Future<void> _persistProfileData() async {
    final username = _userController.text.trim();
    if (username.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _userService.updateProfile(
        uid: _uid,
        username: username,
        bio: _bioController.text.trim(),
        profileImageXFile: _avatarFile,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit SnapDate Profile",
          style: TextStyle(fontFamily: 'Georgia', color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFA3D2CA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatarImage,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFEDF6F4),
                backgroundImage: _avatarFile != null
                    ? appImageProvider(_avatarFile!.path)
                    : appImageProvider(_avatarUrl),
                child: _avatarFile == null && appImageProvider(_avatarUrl) == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.black38,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: "Display Profile Nickname",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Bio",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6A2A8),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _persistProfileData,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "SAVE CHANGES",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
