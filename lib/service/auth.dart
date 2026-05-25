import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(username);
      await _userService.ensureUserDocument(user, username: username);
    }
    return userCredential;
  }

  Future<User?> signIn({required String email, required String password}) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = credential.user;

    if (user != null) {
      await user.reload();
      await _userService.ensureUserDocument(_auth.currentUser ?? user);

      return _auth.currentUser;
    }
    return null;
  }

  Future resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future logout() async {
    await _auth.signOut();
  }
}
