import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  static const String _webClientId =
      '1095142914393-nnk4cbd39bvieooa97tn0m3fvjlah1en.apps.googleusercontent.com';
  static const String _androidClientId =
      '1095142914393-k59uktp9kp76ibfb396eb6s6svjq9r76.apps.googleusercontent.com';

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

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = account.authentication;

      if (googleAuth.idToken == null) {
        return "Missing Google ID token";
      }

      const List<String> scopes = <String>['email', 'profile'];
      final GoogleSignInAuthorizationClient authorizationClient =
          account.authorizationClient;
      GoogleSignInClientAuthorization? authorization =
          await authorizationClient.authorizationForScopes(scopes);

      authorization ??=
          await authorizationClient.authorizeScopes(scopes);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authorization?.accessToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return "Unable to sign in with Google";
      }

      final DocumentReference<Map<String, dynamic>> userDoc =
          _firestore.collection("users").doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userDoc.get();

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
}
