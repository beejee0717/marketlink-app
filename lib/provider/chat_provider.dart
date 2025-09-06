import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/message.dart';
import '../components/snackbar.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  Map<String, dynamic>? userData;

String? role;

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

    

var sellerDoc = await _firestore.collection('sellers').doc(otherUserId).get();
if (sellerDoc.exists) {
  userData = sellerDoc.data();
  role = 'seller';
}

if (userData == null) {
  var riderDoc = await _firestore.collection('riders').doc(otherUserId).get();
  if (riderDoc.exists) {
    userData = riderDoc.data();
    role = 'rider';
  }
}

if (userData == null) {
  var customerDoc =
      await _firestore.collection('customers').doc(otherUserId).get();
  if (customerDoc.exists) {
    userData = customerDoc.data();
    role = 'customer';
  }
}


      return {
  'chatRoomId': doc.id,
  'otherUserId': otherUserId,
  'otherName': '${userData?['firstName']} ${userData?['lastName']}',
  'firstName': userData?['firstName'],
  'profilePicture': userData?['profilePicture'] ?? '',
  'role': role, 
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

  if (trimmedMessage.isEmpty) return;

  // Get roles
  String? senderRole = await getUserRole(currentUserId);
  String? receiverRole = await getUserRole(receiverId);

  if (senderRole == null || receiverRole == null) {
    throw Exception("User not found in any collection.");
  }

  Message newMessage = Message(
    senderId: currentUserId,
    senderRole: senderRole,
    senderEmail: currentUserEmail,
    receiverId: receiverId,
    receiverRole: receiverRole,
    message: trimmedMessage,
    timestamp: timestamp,
  );

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

  Future<String?> getUserRole(String uid) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Check customers
  DocumentSnapshot customerDoc =
      await firestore.collection('customers').doc(uid).get();
  if (customerDoc.exists) {
    return "customer";
  }

  // Check sellers
  DocumentSnapshot sellerDoc =
      await firestore.collection('sellers').doc(uid).get();
  if (sellerDoc.exists) {
    return "seller";
  }

  // Check riders
  DocumentSnapshot riderDoc =
      await firestore.collection('riders').doc(uid).get();
  if (riderDoc.exists) {
    return "rider";
  }

  // Not found in any collection
  return null;
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
