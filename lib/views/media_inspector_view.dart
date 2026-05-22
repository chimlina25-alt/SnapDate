import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MediaInspectorView extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> mediaData;
  const MediaInspectorView({super.key, required this.docId, required this.mediaData});

  @override
  State<MediaInspectorView> createState() => _MediaInspectorViewState();
}

class _MediaInspectorViewState extends State<MediaInspectorView> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.mediaData['isFavorite'] ?? false;
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFav = !_isFav);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('memories')
        .doc(widget.docId)
        .update({'isFavorite': _isFav});
  }

  Future<void> _deletePhoto() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('memories')
        .doc(widget.docId)
        .delete();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory permanently deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent), onPressed: _toggleFavorite),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white70), onPressed: _deletePhoto),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.network(widget.mediaData['imageUrl'] ?? '', fit: BoxFit.contain),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  label: const Text("Share Memory", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing options generated')));
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}