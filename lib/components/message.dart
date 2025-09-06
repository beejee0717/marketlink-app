import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String senderRole;
  final String receiverRole;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  const Message(
      {required this.senderId,
      required this.senderRole,
      required this.senderEmail,
      required this.receiverId,
      required this.receiverRole,
      required this.message,
      required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'senderRole':senderRole,
      'receiverId': receiverId,
      'receiverRole':receiverRole,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
