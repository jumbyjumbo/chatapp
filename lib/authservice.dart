import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //stream auth changes to other widgets
  final FirebaseAuth _auth;
  AuthService(this._auth);
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    UserCredential? userCredential;

    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
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
    // Get the document snapshot
    final docSnapshot = await userDoc.get();

    // Function to add the first message from the chatbot
    Future<String> addFirstMsg(String conversationUID) async {
      DocumentReference message = await FirebaseFirestore.instance
          .collection('globalConvos')
          .doc(conversationUID)
          .collection("messages")
          .add({
        'sender': "chatbot",
        'content':
            "Hi! I'm the chatbot. I'm here to help you get started with your new account. You can start by adding friends and chatting with them!",
        'timestamp': FieldValue.serverTimestamp(),
      });
      return message.id;
    }

    // create the default conversation for the user with the chatbot
    Future<String> createConversation(String name, String convoPicture) async {
      DocumentReference conversationDoc =
          await FirebaseFirestore.instance.collection('globalConvos').add({
        'name': name,
        'members': [user.uid, "chatbot"],
        'convoPicture': convoPicture,
      });
      //create first message from bot
      String lastMsg = await addFirstMsg(conversationDoc.id);
      //make it the last msg sent
      await conversationDoc.update({
        'lastMessage': lastMsg,
      });

      return conversationDoc.id;
    }

    //create chatbot user if recent firestore wipe
    DocumentReference chatbotRef = usersCollection.doc('chatbot');
    DocumentSnapshot chatbotDoc = await chatbotRef.get();

    if (!chatbotDoc.exists) {
      createChatBotUser();
    }

    // If the document does not exist, create it with the user's data
    if (!docSnapshot.exists) {
      //create the conversation in Firestore and get their IDs
      String chatBotConvo = await createConversation("chatbot convo",
          "https://raw.githubusercontent.com/jumbyjumbo/images/main/black%20logo.jpg");

      //Then, add these conversation IDs to the new user's list of conversations
      //and create new user at once
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'convos': [chatBotConvo],
        'profilepicture': user.photoURL,
        'phone': user.phoneNumber,
        'bio': "${user.displayName}'s bio",
        'friends': ["chatbot"],
      });
    } else {
      // If the document does exist, update it with the user's data
      await userDoc.update({
        'name': user.displayName,
        'email': user.email,
        'profilepicture': user.photoURL,
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
            "https://raw.githubusercontent.com/jumbyjumbo/images/main/black%20logo.jpg",
      });
    }
  }

  // Function to handle sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
