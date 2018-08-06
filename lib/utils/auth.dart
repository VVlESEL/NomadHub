import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Auth {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final GoogleSignIn googleSignin = GoogleSignIn();
  static final FirebaseAnalytics analytics = FirebaseAnalytics();
  static final Future<SharedPreferences> sharedPref =
      SharedPreferences.getInstance();

  static Future<bool> googleSignIn() async {
    bool isSignedIn = false;
    GoogleSignInAccount googleSignInAccount = await googleSignin.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    await auth
        .signInWithGoogle(
            idToken: googleSignInAuthentication.idToken,
            accessToken: googleSignInAuthentication.accessToken)
        .then((user) {
      print("Auth googleSignIn! User signed in: User id is: ${user.uid}");
      isSignedIn = true;
    }).catchError((error) {
      print("Auth googleSignIn! Something went wrong! ${error.toString()}");
    });

    return isSignedIn;
  }

  static Future<bool> emailSignIn(String email, String password) async {
    bool isSignedIn = false;

    await auth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((user) {
      print("Auth emailSignIn! User signed in: User id is: ${user.uid}");
      isSignedIn = true;
    }).catchError((error) {
      print("Auth emailSignIn! Something went wrong! ${error.toString()}");
    });

    return isSignedIn;
  }

  static Future<bool> createUser(String email, String password) async {
    bool isCreated = false;

    await auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .then((user) {
      print("Auth createUser! User created: User id is ${user.uid}");
      isCreated = true;
    }).catchError((error) {
      print("Auth createUser! Something went wrong! ${error.toString()}");
    });

    return isCreated;
  }

  static Future<bool> checkSignIn() async {
    bool isSingedIn = await auth.currentUser() != null;

    if (isSingedIn) {
      print("Auth checkSignIn! User is signed in");
      analytics.logLogin();
    } else {
      print("Auth checkSignIn! User is NOT signed in");
    }

    return isSingedIn;
  }

  static Future<bool> signOut() async {
    bool isSingedOut = false;

    await auth.signOut().then((b) {
      print("Auth signOut! User signed out");
      isSingedOut = true;
    }).catchError((error) {
      print("Auth signOut! Something went wrong! ${error.toString()}");
    });

    return isSingedOut;
  }

  static Future<bool> sendPasswordResetEmail(String email) async {
    bool isSent = false;

    await auth.sendPasswordResetEmail(email: email).then((b) {
      print("Auth sendPasswordResetEmail! Reset e-mail sent");
      isSent = true;
    }).catchError((error) {
      print("Auth sendPasswordResetEmail! Something went wrong! ${error
          .toString()}");
    });

    return isSent;
  }
/*
  static Future<bool> deleteUser() async {
    bool isDeleted = false;

    await auth.currentUser().then((user) {
      FirebaseDatabase.instance
          .reference()
          .child("user")
          .child(User.uid)
          .remove();

      //METHOD DOES NOT WORK YET!
      FirebaseStorage.instance.ref().child("user").child(User.uid);

      print("Auth deleteUser! User deleted");
      isDeleted = true;
    }).catchError((error) {
      print("Auth deleteUser! Something went wrong! ${error
          .toString()}");
    });

    return isDeleted;
  }
*/
}
