import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

 final FirebaseAuth _auth =
 FirebaseAuth.instance;


Future signUp({

required String email,
required String password,

}) async {

final userCredential =
await _auth.createUserWithEmailAndPassword(

email: email,
password: password,

);

await userCredential.user
?.sendEmailVerification();

}



Future signIn({

required String email,
required String password,

}) async {

UserCredential credential=
await _auth.signInWithEmailAndPassword(

email: email,
password: password,

);

User? user=
credential.user;


if(user!=null){

await user.reload();

user=_auth.currentUser;


if(!user!.emailVerified){

await user.sendEmailVerification();

await _auth.signOut();

throw FirebaseAuthException(

code:"email-not-verified",
message:"Please verify email first"

);

}

}

}


Future resetPassword(
String email
) async {

await _auth.sendPasswordResetEmail(
email: email,
);

}



Future logout() async{

await _auth.signOut();

}

}