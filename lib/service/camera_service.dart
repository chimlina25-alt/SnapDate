import 'package:camera/camera.dart';

class CameraService {
  Future<List<CameraDescription>> availableDeviceCameras() {
    return availableCameras();
  }

  Future<CameraController> createController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    return controller;
  }
}
