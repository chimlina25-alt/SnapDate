import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../models/memory.dart';
import 'storage_service.dart';

class MemoryService {
  MemoryService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  CollectionReference<Map<String, dynamic>> _memories(String uid) {
    return _firestore.collection('memories');
  }

  Stream<List<Memory>> streamMemories(String uid, {int? limit}) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] ?? a.data()['timestamp']) as Timestamp?;
            final bTime = (b.data()['createdAt'] ?? b.data()['timestamp']) as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          var list = docs.map(Memory.fromDoc).toList();
          if (limit != null) {
            list = list.take(limit).toList();
          }
          return list;
        });
  }

  Stream<List<Memory>> streamFavorites(String uid) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] ?? a.data()['timestamp']) as Timestamp?;
            final bTime = (b.data()['createdAt'] ?? b.data()['timestamp']) as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          return docs.map(Memory.fromDoc).toList();
        });
  }

  Stream<List<Memory>> streamDay(String uid, DateTime date) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .where('dateKey', isEqualTo: dateKey(date))
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] ?? a.data()['timestamp']) as Timestamp?;
            final bTime = (b.data()['createdAt'] ?? b.data()['timestamp']) as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          return docs.map(Memory.fromDoc).toList();
        });
  }

  Stream<List<Memory>> streamRange(String uid, DateTime start, DateTime end) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          final list = docs.map(Memory.fromDoc).toList();
          final filtered = list.where((m) {
            return m.memoryDate.isAtSameMomentAs(start) ||
                (m.memoryDate.isAfter(start) && m.memoryDate.isBefore(end));
          }).toList();
          filtered.sort((a, b) => a.memoryDate.compareTo(b.memoryDate));
          return filtered;
        });
  }

  Stream<List<Memory>> streamOnThisDayLastYear(String uid, DateTime date) {
    final lastYear = DateTime(date.year - 1, date.month, date.day);
    return streamDay(uid, lastYear);
  }

  Future<void> addImageMemory({
    required String uid,
    File? file,
    XFile? xFile,
  }) async {
    final now = DateTime.now();
    final upload = await _storageService.uploadImage(
      ownerId: uid,
      file: file,
      xFile: xFile,
      folder: 'memories',
    );
    final memory = Memory(
      id: '',
      ownerId: uid,
      mediaUrl: upload.url,
      storagePath: upload.path,
      type: MemoryType.image,
      dateKey: dateKey(now),
      memoryDate: DateTime(now.year, now.month, now.day),
      isFavorite: false,
    );
    final doc = _memories(uid).doc();
    await doc.set({...memory.toMap(), 'memoryId': doc.id});
  }

  Future<void> addVideoMemory({
    required String uid,
    File? file,
    XFile? xFile,
  }) async {
    final now = DateTime.now();
    final upload = await _storageService.uploadVideo(
      ownerId: uid,
      file: file,
      xFile: xFile,
      folder: 'memories',
    );
    final memory = Memory(
      id: '',
      ownerId: uid,
      mediaUrl: upload.url,
      storagePath: upload.path,
      type: MemoryType.video,
      dateKey: dateKey(now),
      memoryDate: DateTime(now.year, now.month, now.day),
      isFavorite: false,
    );
    final doc = _memories(uid).doc();
    await doc.set({...memory.toMap(), 'memoryId': doc.id});
  }

  Future<void> setFavorite({
    required String uid,
    required String memoryId,
    required bool isFavorite,
  }) async {
    await _memories(uid).doc(memoryId).update({'isFavorite': isFavorite});
  }

  Future<void> deleteMemory({
    required String uid,
    required String memoryId,
    required String storagePath,
  }) async {
    await _memories(uid).doc(memoryId).delete();
    await _storageService.deleteByPath(storagePath);
  }

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
