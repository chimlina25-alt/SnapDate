import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'media_inspector_view.dart';
import '../utils/app_image.dart';
import '../models/memory.dart';
import '../service/memory_service.dart';

class FavoritesView extends StatelessWidget {
  final VoidCallback onBackToHome;
  const FavoritesView({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final memoryService = MemoryService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Memory>>(
        stream: memoryService.streamFavorites(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No favorite photos yet.",
                style: TextStyle(color: Colors.black38, fontFamily: 'Georgia'),
              ),
            );
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
              final imageProvider = appImageProvider(memory.mediaUrl);
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
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: memory.type == MemoryType.video
                      ? const Icon(Icons.play_circle_fill, color: Colors.black45, size: 42)
                      : imageProvider == null
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
}
