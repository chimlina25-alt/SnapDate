import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileView extends StatefulWidget {
  final String currentUsername;
  final String currentAvatar;
  final List<dynamic> currentHighlights;
  
  const EditProfileView({
    super.key, 
    required this.currentUsername, 
    required this.currentAvatar, 
    required this.currentHighlights
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _userController;
  late List<dynamic> _workingHighlights;
  String _avatarDataString = "";
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.currentUsername);
    _workingHighlights = List.from(widget.currentHighlights);
    _avatarDataString = widget.currentAvatar;
  }

  Future<void> _pickAvatarImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (selected != null) {
      final bytes = await File(selected.path).readAsBytes();
      setState(() {
        _avatarDataString = "data:image/png;base64,${base64Encode(bytes)}";
      });
    }
  }

  Future<void> _pickHighlightSlotImage(int index) async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (selected != null) {
      final bytes = await File(selected.path).readAsBytes();
      final base64Image = "data:image/png;base64,${base64Encode(bytes)}";
      
      setState(() {
        if (index < _workingHighlights.length) {
          _workingHighlights[index] = base64Image;
        } else {
          _workingHighlights.add(base64Image);
        }
      });
    }
  }

  Future<void> _persistProfileData() async {
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'username': _userController.text.trim(),
      'avatarUrl': _avatarDataString,
      'highlights': _workingHighlights,
    }, SetOptions(merge: true));
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit SnapDate Profile", style: TextStyle(fontFamily: 'Georgia', color: Colors.black87)), 
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
                backgroundImage: _avatarDataString.isNotEmpty 
                    ? MemoryImage(base64Decode(_avatarDataString.split(',').last)) 
                    : null,
                child: _avatarDataString.isEmpty ? const Icon(Icons.add_a_photo, size: 30, color: Colors.black38) : null,
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
          const SizedBox(height: 30),
          const Text("Highlights Album Slots (Tap to edit/add photo)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: 4,
            itemBuilder: (ctx, i) {
              final hasImg = i < _workingHighlights.length;
              return GestureDetector(
                onTap: () => _pickHighlightSlotImage(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6F4), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                    image: hasImg ? DecorationImage(image: MemoryImage(base64Decode(_workingHighlights[i].split(',').last)), fit: BoxFit.cover) : null,
                  ),
                  child: !hasImg ? const Icon(Icons.add_photo_alternate_outlined, color: Colors.black26) : null,
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6A2A8), elevation: 0),
              onPressed: _persistProfileData, 
              child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}