import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationServices {
  CollectionReference userDetails = FirebaseFirestore.instance.collection(
    'UsersDetails',
  );
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Initialize Firebase Auth
      final auth = FirebaseAuth.instance;

      // Create user with email and password
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Return the newly created user
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else {
        throw Exception('Error creating user: ${e.message}');
      }
    } catch (e) {
      // Handle all other errors
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> addUserDetails(String fullName, userEmail) async {
    await userDetails.doc(userEmail).set({
      'UserName': fullName,
      "Email": userEmail,
      "PhoneNumber": "",
      "BusinesName": "",
      "LocationAdddress": "",
      "ProfileImage": "",
    });
  }

  Future<void> createCustomerAccount(
    String fullName,
    phoneNumber,
    emailAddres,
  ) async {
    await FirebaseFirestore.instance
        .collection('customerDetails')
        .doc(emailAddres.toString())
        .set({
          'email': emailAddres,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'profileImageUrl': 'profileUrl',
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'rating': 0,
          'totalRatings': 0,
        });
  }
}
