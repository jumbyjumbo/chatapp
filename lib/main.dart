import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'authservice.dart';

import 'login.dart';
import 'convos.dart';

void main() async {
  //make sure widgets load before anything else
  WidgetsFlutterBinding.ensureInitialized();

  //load .env file
  await dotenv.load();

  //initialize firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Instantiate AuthService.
    final AuthService authService = AuthService(
      FirebaseAuth.instance,
    );

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data == null) {
              // User is signed out, show Login screen.
              return const Login();
            } else {
              // User is signed in, show ConvoList.
              return const ConvoList();
            }
          } else {
            // Show nothing
            return Container(
              color: Colors.transparent,
            );
          }
        },
      ),
    );
  }
}
