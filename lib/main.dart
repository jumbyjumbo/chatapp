import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'backend stuff/firebase_options.dart';
import 'backend stuff/authservice.dart';
import 'pages/login.dart';
import 'pages/convos.dart';
import 'pages/usernameselection.dart';

void main() async {
  //make sure widgets load before anything else
  WidgetsFlutterBinding.ensureInitialized();

  //initialize firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Create a navigator key to navigate without context

  @override
  Widget build(BuildContext context) {
    // init AuthService.
    final AuthService authService = AuthService(
      FirebaseAuth.instance,
    );

    return CupertinoApp(
      //app title
      title: "Flow",

      // Set theme.
      theme: CupertinoThemeData(
        primaryColor: CupertinoTheme.brightnessOf(context) == Brightness.light
            ? CupertinoColors.black
            : CupertinoColors.white,
      ),

      //stream if user is logged in or not
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data == null) {
              // User is signed out, show Login screen.
              return const Login();
            } else {
              // User is signed in, check if they have a username

              // Get user document
              final userDoc = FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid);

              return FutureBuilder<DocumentSnapshot>(
                  future: userDoc.get(),
                  builder: (context, docSnapshot) {
                    if (docSnapshot.hasData &&
                        docSnapshot.data != null &&
                        docSnapshot.data!.exists) {
                      final userData =
                          docSnapshot.data!.data() as Map<String, dynamic>?;
                      if (userData!['username'] == null) {
                        // Navigate to username selection page
                        return const UsernameSelection();
                      } else {
                        // User has a username, show ConvoList
                        return const ConvoList();
                      }
                    } else {
                      // Show nothing
                      return const SizedBox.shrink();
                    }
                  });
            }
          } else {
            // Show nothing
            return const SizedBox.shrink();
          }
        },
      ),
      //remove debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}
