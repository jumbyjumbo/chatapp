import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  //stream auth changes to other widgets
  final FirebaseAuth auth;
  AuthService(this.auth);
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    UserCredential? userCredential;

    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      userCredential = await firebaseAuth.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        userCredential = await firebaseAuth.signInWithCredential(credential);
      }
    }
    if (userCredential != null) {
      // Here we're getting the user from UserCredential.
      User? user = userCredential.user;
      if (user != null) {
        // store user in Firestore
        await storeUserInFirestore(user);
      }
    }
  }

  // Function to store user data in Firestore if the user does not already exist
  Future<void> storeUserInFirestore(User user) async {
    // Get the 'users' collection
    final usersCollection = FirebaseFirestore.instance.collection('users');
    // Get the document with the same UID as the user
    final userDoc = usersCollection.doc(user.uid);
    // Get the user's info
    final docSnapshot = await userDoc.get();

    //lookup and create chatbot user if recent firestore wipe
    DocumentReference chatbotRef = usersCollection.doc('chatbot');
    DocumentSnapshot chatbotDoc = await chatbotRef.get();
    if (!chatbotDoc.exists) {
      createChatBotUser();
    }

    // If the document does not exist, create it with the user's data
    if (!docSnapshot.exists) {
      //Then, add these conversation IDs to the new user's list of conversations
      //and create new user at once
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'convos': [],
        'profilepicture': user.photoURL,
        'phone': user.phoneNumber,
        'bio': "${user.displayName}'s bio",
        'friends': ["chatbot"],
      });
    } else {
      // If the document does exist, update it with the user's data
      await userDoc.update({
        'email': user.email,
        'phone': user.phoneNumber,
      });
    }
  }

  // Function to create chatbot user in Firestore if it does not already exist
  Future<void> createChatBotUser() async {
    // Get the 'users' collection
    final usersCollection = FirebaseFirestore.instance.collection('users');
    // Get the document with the same UID as the chatbot
    final chatBotDoc = usersCollection.doc("chatbot");
    // Get the document snapshot
    final docSnapshot = await chatBotDoc.get();

    // If the document does not exist, create it with the chatbot's data
    if (!docSnapshot.exists) {
      await chatBotDoc.set({
        'name': "chatbot",
        'profilepicture':
            "https://raw.githubusercontent.com/jumbyjumbo/images/main/icon-192.png",
      });
    }
  }

  // Function to handle sign out
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
}
