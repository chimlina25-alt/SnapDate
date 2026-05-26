import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  Future<List<CameraDescription>> availableDeviceCameras() {
    return availableCameras();
  }

  Future<CameraController> createController(CameraDescription camera) async {
    final targets = camera.lensDirection == CameraLensDirection.front
        ? <ResolutionPreset>[ResolutionPreset.max, ResolutionPreset.medium]
        : <ResolutionPreset>[ResolutionPreset.high];

    CameraController? controller;
    Object? lastError;

    for (final preset in targets) {
      try {
        controller = CameraController(
          camera,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await controller.initialize();
        return controller;
      } catch (error, stackTrace) {
        lastError = error;
        debugPrint(
          'Camera init failed for ${camera.lensDirection} at $preset: $error',
        );
        debugPrint('$stackTrace');
        await controller?.dispose().catchError((_) {});
      }
    }

    throw CameraException(
      'camera_init_failed',
      'Unable to initialize camera ${camera.name} for lens ${camera.lensDirection}',
    );
  }

  Future<XFile?> takePictureSafely(
    CameraController controller,
    CameraDescription camera,
  ) async {
    if (!controller.value.isInitialized) {
      return null;
    }

    if (controller.value.isTakingPicture) {
      return null;
    }

    try {
      await _lockFocusAndExposure(controller);
      return await controller.takePicture();
    } on CameraException catch (e, stackTrace) {
      debugPrint('Safe picture capture failed: ${e.code} ${e.description}');
      debugPrint('$stackTrace');

      if (camera.lensDirection == CameraLensDirection.front) {
        try {
          final fallbackController = CameraController(
            camera,
            ResolutionPreset.medium,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.yuv420,
          );
          await fallbackController.initialize();
          await Future.delayed(const Duration(milliseconds: 300));
          await _lockFocusAndExposure(fallbackController);
          final file = await fallbackController.takePicture();
          await fallbackController.dispose();
          return file;
        } catch (fallbackError, fallbackStackTrace) {
          debugPrint('Front camera fallback failed: $fallbackError');
          debugPrint('$fallbackStackTrace');
        }
      }

      rethrow;
    }
  }

  Future<void> _lockFocusAndExposure(CameraController controller) async {
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Could not set focus mode: $e');
    }

    try {
      await controller.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('Could not set exposure mode: $e');
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }
}
