import 'package:cloud_firestore/cloud_firestore.dart';
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

  UserInformation(
      {required this.uid,
      required this.firstName,
      required this.lastName,
      required this.address,
      required this.email,
      required this.contactNumber,
      required this.role,
      required this.profilePicturePath,
      required this.approved,
      required this.dateLastLogin})
      : profilePicture = getProfileImage(profilePicturePath);

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
    if (!context.mounted) return null;

    Provider.of<UserProvider>(context, listen: false).setUser(fetchedUser);
    return fetchedUser;
  } else {
    if (!context.mounted) return null;
    return null;
  }
}
