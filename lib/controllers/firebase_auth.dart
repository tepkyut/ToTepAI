import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  static const String _webClientId =
      '649100271753-orv5qgouvr54r29cp80ljbidf6bienbf.apps.googleusercontent.com';
  static const String _androidClientId =
      '649100271753-425249lhpf8hhmgv6u264nr3mh4k8ihb.apps.googleusercontent.com';
  static const List<String> _googleScopeHints = <String>['email', 'profile'];

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? _webClientId : _androidClientId,
      serverClientId: _webClientId,
    );
    _googleInitialized = true;
  }

  // Register a new user
  Future<String> registerNewUser(
    String email,
    String name,
    String password,
  ) async {
    String result = "Something went wrong";
    try {
      // 1. Create user in Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Save user details in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "name": name,
        "uid": userCredential.user!.uid,
        "email": email,
        "profileImage": "",
        "pinCode": "",
        "purok": "",
        "barangay": "",
        "city": "",
        "pass": password,
        "status": "active",
        "hasWelcomeNotifications": false, // Initialize welcome notifications flag
      });

      result = "success";
    } catch (e) {
      result = e.toString();
    }

    return result;
  }

  // Sign in or register with Google
  Future<String> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return "Google sign-in is not supported on this platform.";
      }

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: _googleScopeHints);
      final GoogleSignInAuthentication googleAuth = account.authentication;

      if (googleAuth.idToken == null) {
        return "Missing Google ID token";
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user == null) {
        return "Unable to sign in with Google";
      }

      final DocumentReference<Map<String, dynamic>> userDoc = _firestore
          .collection("users")
          .doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await userDoc
          .get();

      if (!snapshot.exists) {
        await userDoc.set({
          "name": user.displayName ?? "",
          "uid": user.uid,
          "email": user.email ?? "",
          "profileImage": user.photoURL ?? "",
          "pinCode": "",
          "purok": "",
          "barangay": "",
          "city": "",
          "pass": "",
          "status": "active",
          "hasWelcomeNotifications": false, // Initialize welcome notifications flag
        });
      }

      return "success";
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return "cancelled";
      }
      return e.description ?? "Google sign-in failed";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Google sign-in failed";
    } catch (e) {
      return e.toString();
    }
  }

  // Update user status
  Future<String> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection("users").doc(userId).update({
        "status": status.toLowerCase(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  // Get current user status
  Future<String> getCurrentUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) return "User not authenticated";

    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?["status"] ?? "active";
      }
      return "User not found";
    } catch (e) {
      return e.toString();
    }
  }
}
