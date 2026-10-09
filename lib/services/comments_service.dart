
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'preference_service.dart';

class CommentsService {
  // Use Firestore collection 'station_comments' with documents named by stationId
  static bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  static Future<List<Map<String, dynamic>>> getComments(String stationId) async {
    if (_firebaseAvailable) {
      try {
        final col = FirebaseFirestore.instance.collection('station_comments').doc(stationId).collection('comments');
        final snapshot = await col.orderBy('timestamp', descending: true).get();
        return snapshot.docs.map((d) => d.data()).toList();
      } catch (e) {
        debugPrint('Firestore getComments failed: $e');
      }
    }

    return PreferenceService.getComments(stationId);
  }

  static Future<void> addComment(String stationId, String author, String text) async {
    if (_firebaseAvailable) {
      try {
        final col = FirebaseFirestore.instance.collection('station_comments').doc(stationId).collection('comments');
        await col.add({
          'author': author,
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      } catch (e) {
        debugPrint('Firestore addComment failed: $e');
      }
    }

    // fallback to local preference storage
    await PreferenceService.addComment(stationId, author, text);
  }
}
