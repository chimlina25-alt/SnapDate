import '../models/memory.dart';
import 'memory_service.dart';

class GalleryService {
  GalleryService({MemoryService? memoryService})
      : _memoryService = memoryService ?? MemoryService();

  final MemoryService _memoryService;

  Stream<List<Memory>> streamGallery(String uid) {
    return _memoryService.streamMemories(uid);
  }
}
