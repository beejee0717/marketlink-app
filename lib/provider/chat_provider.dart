import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/message.dart';
import '../components/snackbar.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;

  Future<void> initialize(String userId, BuildContext context) async {
    await _fetchChatRooms(userId, context);
  }

  Future<void> _fetchChatRooms(String userId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore.collection('chat_room').get();

      _chatRooms = await Future.wait(querySnapshot.docs.where((doc) {
        var docId = doc.id;
        return docId.split('_').contains(userId);
      }).map((doc) async {
        var docId = doc.id;
        String otherUserId = docId.split('_').firstWhere((id) => id != userId);

        var userDoc =
            await _firestore.collection('sellers').doc(otherUserId).get();
        var userData = userDoc.exists ? userDoc.data() : null;

        if (userData == null) {
          userDoc =
              await _firestore.collection('customers').doc(otherUserId).get();
          userData = userDoc.data();
        }

        return {
          'chatRoomId': doc.id,
          'otherUserId': otherUserId,
          'otherName': '${userData?['firstName']} ${userData?['lastName']}',
          'firstName': userData?['firstName'],
          'profilePicture': userData?['profilePicture'] ?? '',
        };
      }).toList());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      errorSnackbar(context, e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(context, String userId, String receiverId) async {
    try {
      WriteBatch batch = _firestore.batch();

      List<String> ids = [userId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final messagesCollectionRef = _firestore
          .collection('chat_room')
          .doc(chatRoomId)
          .collection('messages');

      final messagesSnapshot = await messagesCollectionRef.get();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final chatRoomRef = _firestore.collection('chat_room').doc(chatRoomId);
      batch.delete(chatRoomRef);

      await batch.commit();

      successSnackbar(context, 'Successfully removed');
    } catch (e) {
      errorSnackbar(context, e.toString());
    }
  }
}

class MessagesProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<void> sendMessage(
    String receiverId,
    String message,
  ) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();
    String trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      return;
    }
    Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: trimmedMessage,
        timestamp: timestamp);

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    DocumentSnapshot docSnapshot =
        await _firebaseFirestore.collection('chat_room').doc(chatRoomId).get();

    if (!docSnapshot.exists) {
      await _firebaseFirestore.collection('chat_room').doc(chatRoomId).set({
        'exists': true,
      });
    }

    await _firebaseFirestore
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    notifyListeners();
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    return _firebaseFirestore
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
