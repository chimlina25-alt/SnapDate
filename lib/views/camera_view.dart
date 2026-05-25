import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../service/camera_service.dart';
import '../service/memory_service.dart';

class CameraMainView extends StatefulWidget {
  const CameraMainView({super.key});

  @override
  State<CameraMainView> createState() => _CameraMainViewState();
}

class _CameraMainViewState extends State<CameraMainView> {
  final MemoryService _memoryService = MemoryService();
  final CameraService _cameraService = CameraService();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _photoMode = true;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera({int cameraIndex = 0}) async {
    setState(() => _isCameraReady = false);
    try {
      _cameras = await _cameraService.availableDeviceCameras();
      if (_cameras.isEmpty) return;

      final index = cameraIndex.clamp(0, _cameras.length - 1);
      final oldController = _cameraController;
      final controller = await _cameraService.createController(_cameras[index]);

      _cameraController = controller;
      _cameraIndex = index;
      await oldController?.dispose();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() => _isCameraReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCameraReady = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start camera: $e')),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isProcessing || _isRecording) return;
    await _setupCamera(cameraIndex: (_cameraIndex + 1) % _cameras.length);
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (controller == null || !controller.value.isInitialized || uid == null) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final photo = await controller.takePicture();
      await _memoryService.addImageMemory(uid: uid, file: File(photo.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded to memories.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleVideoRecording() async {
    final controller = _cameraController;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (controller == null || !controller.value.isInitialized || uid == null) {
      return;
    }

    if (_isRecording) {
      setState(() => _isProcessing = true);
      try {
        final video = await controller.stopVideoRecording();
        setState(() => _isRecording = false);
        await _memoryService.addVideoMemory(uid: uid, file: File(video.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video uploaded to memories.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload video: $e')),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
      return;
    }

    try {
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not record video: $e')),
      );
    }
  }

  Future<void> _handleShutter() async {
    if (_isProcessing) return;
    if (_photoMode) {
      await _capturePhoto();
    } else {
      await _toggleVideoRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _isCameraReady && _cameraController != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: ready
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD6A2A8)),
                  ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              onPressed: _cameras.length < 2 ? null : _switchCamera,
            ),
          ),
          if (_isProcessing)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD6A2A8)),
                ),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeToggle(
                    photoMode: _photoMode,
                    enabled: !_isRecording && !_isProcessing,
                    onChanged: (value) => setState(() => _photoMode = value),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: ready ? _handleShutter : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _photoMode
                                  ? Colors.white
                                  : _isRecording
                                      ? Colors.redAccent
                                      : const Color(0xFFD6A2A8),
                              shape: _isRecording
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius:
                                  _isRecording ? BorderRadius.circular(14) : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool photoMode;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.photoMode,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Photo',
            selected: photoMode,
            enabled: enabled,
            onTap: () => onChanged(true),
          ),
          _ModeButton(
            label: 'Video',
            selected: !photoMode,
            enabled: enabled,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black87 : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
