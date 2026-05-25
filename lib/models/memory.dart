import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum MemoryType { image, video }

class Memory {
  final String id;
  final String ownerId;
  final String mediaUrl;
  final String storagePath;
  final MemoryType type;
  final String dateKey;
  final DateTime memoryDate;
  final bool isFavorite;
  final DateTime? createdAt;

  const Memory({
    required this.id,
    required this.ownerId,
    required this.mediaUrl,
    required this.storagePath,
    required this.type,
    required this.dateKey,
    required this.memoryDate,
    required this.isFavorite,
    this.createdAt,
  });

  String get imagePath => mediaUrl;

  factory Memory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final path = (data['imagePath'] ??
            data['mediaPath'] ??
            data['mediaUrl'] ??
            data['imageUrl'] ??
            '')
        .toString();
    final dateKey = (data['dateKey'] ?? data['dateGroup'] ?? '').toString();
    final memoryDate =
        (data['memoryDate'] as Timestamp?)?.toDate() ?? _dateFromKey(dateKey);
    final typeName = (data['type'] ?? 'image').toString();
    return Memory(
      id: doc.id,
      ownerId: (data['userId'] ?? data['ownerId'] ?? '').toString(),
      mediaUrl: path,
      storagePath: (data['storagePath'] ?? data['imagePath'] ?? '').toString(),
      type: typeName == 'video' ? MemoryType.video : MemoryType.image,
      dateKey: dateKey.isEmpty ? DateFormat('yyyy-MM-dd').format(memoryDate) : dateKey,
      memoryDate: memoryDate,
      isFavorite: data['isFavorite'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': ownerId,
      'ownerId': ownerId,
      'memoryId': id,
      'imagePath': mediaUrl,
      'mediaPath': mediaUrl,
      'mediaUrl': mediaUrl,
      'imageUrl': mediaUrl,
      'storagePath': storagePath,
      'type': type.name,
      'dateKey': dateKey,
      'dateGroup': dateKey,
      'memoryDate': Timestamp.fromDate(memoryDate),
      'isFavorite': isFavorite,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _dateFromKey(String key) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(key);
    } catch (_) {
      return DateTime.now();
    }
  }
}
