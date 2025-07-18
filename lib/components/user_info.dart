import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';

class UserInformation {
 final String uid;
  final String firstName;
  final String lastName;
  final String address;
  final String email;
  final String contactNumber;
  final String role;
  final String profilePicturePath;
  final ImageProvider profilePicture;
  final bool approved;
  final DateTime? dateLastLogin;

  UserInformation({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.email,
    required this.contactNumber,
    required this.role,
    required this.profilePicturePath,
    required this.approved,
    required this.dateLastLogin,
  }) : profilePicture = getProfileImage(profilePicturePath);

  UserInformation copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? address,
    String? email,
    String? contactNumber,
    String? role,
    String? profilePicturePath,
    bool? approved,
    DateTime? dateLastLogin,
  }) {
    return UserInformation(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      role: role ?? this.role,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      approved: approved ?? this.approved,
      dateLastLogin: dateLastLogin ?? this.dateLastLogin,
    );
  }

  factory UserInformation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserInformation(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address:  data['address'] ?? '',
      role: data['role'] ?? '',
      profilePicturePath: data['profilePicture'] ?? '',
      approved: data['approved'] ?? false,
      dateLastLogin: (data['dateLastLogin'] != null)
          ? (data['dateLastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  static ImageProvider getProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/images/.png');
    } else if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }
}

Future<UserInformation?> fetchAndSetUserData(
    String uid, BuildContext context) async {
  DocumentSnapshot userDocument =
      await FirebaseFirestore.instance.collection('customers').doc(uid).get();

  if (userDocument.exists) {
    UserInformation fetchedUser = UserInformation.fromFirestore(userDocument);

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .update({'fcmToken': token});
    }

    if (!context.mounted) return null;

    Provider.of<UserProvider>(context, listen: false).setUser(fetchedUser);
    return fetchedUser;
  } else {
    if (!context.mounted) return null;
    return null;
  }
}
