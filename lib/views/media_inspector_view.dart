import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_image.dart';
import '../models/memory.dart';
import '../service/memory_service.dart';
import 'share_memory_view.dart';

class MediaInspectorView extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? mediaData;
  final String? memoryId;
  final Memory? memory;
  const MediaInspectorView({
    super.key,
    this.docId,
    this.mediaData,
    this.memoryId,
    this.memory,
  });

  @override
  State<MediaInspectorView> createState() => _MediaInspectorViewState();
}

class _MediaInspectorViewState extends State<MediaInspectorView> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  final MemoryService _memoryService = MemoryService();
  late bool _isFav;
  late String _memoryId;
  late String _mediaUrl;
  late String _storagePath;
  late MemoryType _type;

  @override
  void initState() {
    super.initState();
    _memoryId = widget.memory?.id ?? widget.memoryId ?? widget.docId ?? '';
    _mediaUrl =
        widget.memory?.mediaUrl ??
        (widget.mediaData?['imagePath'] ??
                widget.mediaData?['mediaUrl'] ??
                widget.mediaData?['imageUrl'] ??
                '')
            .toString();
    _storagePath =
        widget.memory?.storagePath ??
        (widget.mediaData?['storagePath'] ??
                widget.mediaData?['imagePath'] ??
                '')
            .toString();
    _type =
        widget.memory?.type ??
        ((widget.mediaData?['type'] ?? 'image') == 'video'
            ? MemoryType.video
            : MemoryType.image);
    _isFav =
        widget.memory?.isFavorite ?? widget.mediaData?['isFavorite'] == true;
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFav = !_isFav);
    await _memoryService.setFavorite(
      uid: _uid,
      memoryId: _memoryId,
      isFavorite: _isFav,
    );
  }

  Future<void> _deletePhoto() async {
    await _memoryService.deleteMemory(
      uid: _uid,
      memoryId: _memoryId,
      storagePath: _storagePath,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory permanently deleted')),
      );
    }
  }

  Future<void> _shareMemory() async {
    if (_mediaUrl.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share memory: URL is missing.'),
          ),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShareMemoryView(mediaUrl: _mediaUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: _deletePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            onPressed: _shareMemory,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: _type == MemoryType.video
                    ? const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                        size: 96,
                      )
                    : appImage(
                        _mediaUrl,
                        fit: BoxFit.contain,
                        fallback: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 80,
                        ),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  label: const Text(
                    "Share Memory",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _shareMemory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
