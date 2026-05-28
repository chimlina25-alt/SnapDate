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
      if (oldController != null) {
        await oldController.dispose();
        _cameraController = null;
      }

      final controller = await _cameraService.createController(_cameras[index]);
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraIndex = index;
        _isCameraReady = controller.value.isInitialized;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCameraReady = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start camera: $e')));
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isProcessing) return;
    final targetLens =
        _cameras[_cameraIndex].lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final nextIndex = _cameras.indexWhere(
      (desc) => desc.lensDirection == targetLens,
    );
    if (nextIndex < 0) return;
    await _setupCamera(cameraIndex: nextIndex);
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (controller == null || !controller.value.isInitialized || uid == null) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final photo =
          _cameras[_cameraIndex].lensDirection == CameraLensDirection.front
          ? await _takeFrontPhoto()
          : await _cameraService.takePictureSafely(
              controller,
              _cameras[_cameraIndex],
            );

      if (photo == null) {
        throw Exception('Unable to capture photo safely.');
      }

      await _memoryService.addImageMemory(uid: uid, xFile: photo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded to memories.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not upload photo: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<XFile?> _takeFrontPhoto() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }

    try {
      return await _cameraService.takePictureSafely(
        controller,
        _cameras[_cameraIndex],
      );
    } on CameraException catch (_) {
      await _setupCamera(cameraIndex: _cameraIndex);
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return null;
      }
      return await _cameraService.takePictureSafely(
        _cameraController!,
        _cameras[_cameraIndex],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: ready
                ? CameraPreview(controller)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: ready && !_isProcessing ? _capturePhoto : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
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
