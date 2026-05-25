import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    var query = _memories(uid)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snap) => snap.docs.map(Memory.fromDoc).toList());
  }

  Stream<List<Memory>> streamFavorites(String uid) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .where('isFavorite', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Memory.fromDoc).toList());
  }

  Stream<List<Memory>> streamDay(String uid, DateTime date) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .where('dateKey', isEqualTo: dateKey(date))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Memory.fromDoc).toList());
  }

  Stream<List<Memory>> streamRange(String uid, DateTime start, DateTime end) {
    return _memories(uid)
        .where('userId', isEqualTo: uid)
        .where('memoryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('memoryDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('memoryDate')
        .snapshots()
        .map((snap) => snap.docs.map(Memory.fromDoc).toList());
  }

  Stream<List<Memory>> streamOnThisDayLastYear(String uid, DateTime date) {
    final lastYear = DateTime(date.year - 1, date.month, date.day);
    return streamDay(uid, lastYear);
  }

  Future<void> addImageMemory({required String uid, required File file}) async {
    final now = DateTime.now();
    final upload = await _storageService.uploadImage(
      ownerId: uid,
      file: file,
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

  Future<void> addVideoMemory({required String uid, required File file}) async {
    final now = DateTime.now();
    final upload = await _storageService.uploadVideo(
      ownerId: uid,
      file: file,
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
