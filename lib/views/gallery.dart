import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'media_inspector_view.dart';
import '../utils/app_image.dart';
import '../models/memory.dart';
import '../service/gallery_service.dart';

class GalleryView extends StatelessWidget {
  final VoidCallback onBackToHome;
  const GalleryView({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final galleryService = GalleryService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Memory>>(
        stream: galleryService.streamGallery(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final memories = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: memories.length,
            itemBuilder: (ctx, i) {
              final memory = memories[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MediaInspectorView(memoryId: memory.id, memory: memory),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: memory.type == MemoryType.image &&
                            appImageProvider(memory.mediaUrl) != null
                        ? DecorationImage(
                            image: appImageProvider(memory.mediaUrl)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: memory.type == MemoryType.video
                      ? const Icon(Icons.play_circle_fill, color: Colors.black45, size: 42)
                      : appImageProvider(memory.mediaUrl) == null
                          ? const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.black26,
                            )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Gallery Vault Empty",
        style: TextStyle(color: Colors.black38, fontFamily: 'Georgia'),
      ),
    );
  }
}
