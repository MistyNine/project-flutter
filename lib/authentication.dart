import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> login(String username, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: username,
        password: password,
      );
      return userCredential.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: username,
        password: password,
      );
      return userCredential.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    // Implement logout logic here
    // clear user session 
    await _auth.signOut();
    // Clear any stored data on Local Storage or Shared Preferences if needed
  }

  bool isAuthenticated() {
    // Check if the user is authenticated
    // check value from local storage or shared preferences
    return true; // Placeholder implementation
  }
  Future<bool> resetpassword(String username) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: username,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  String? getEmail() {
    String? email;
    try {
      email = _auth.currentUser!.email;
    } catch (e) {
      email = "Guest";
    }
    return email;
  }
}
