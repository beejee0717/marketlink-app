import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 🔹 Foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final notification = message.notification!;
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}

Future<void> getToken(DocumentSnapshot userDoc, String role) async {
  final uid = userDoc.id;
  final token = await FirebaseMessaging.instance.getToken();

  if (token == null) return;

  final firestore = FirebaseFirestore.instance;

  final collections = ['customers', 'sellers', 'riders'];

  final batch = firestore.batch();

  for (final col in collections) {
    final query = await firestore
        .collection(col)
        .where('fcmToken', isEqualTo: token)
        .get();

    for (var doc in query.docs) {
      if (doc.id != uid) {
        batch.update(doc.reference, {"fcmToken": FieldValue.delete()});
      }
    }
  }

  final userRef = firestore.collection('${role.toLowerCase()}s').doc(uid);
  batch.update(userRef, {"fcmToken": token});

  await batch.commit();

  debugging("Token saved uniquely: $token");
}

Future<void> removeToken(BuildContext context, String role) async {
  final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
  if (userId == null) return;

  final firestore = FirebaseFirestore.instance;

  await firestore.collection(role).doc(userId).update({
    "fcmToken": FieldValue.delete(),
  });

  await FirebaseMessaging.instance.deleteToken();

  debugging("Token removed for $role: $userId");
}
