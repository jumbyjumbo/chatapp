import 'dart:async';
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService authService = AuthService(FirebaseAuth.instance);
  Timer? inactivityTimer;

  //user activity detected, reset inactivity timer
  void userActivityDetected() {
    if (inactivityTimer != null) {
      inactivityTimer!.cancel();
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      authService.markUserOnline(currentUser.uid);
    }
    inactivityTimer = Timer(const Duration(minutes: 10), () {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        authService.markUserOffline(currentUser.uid);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (state == AppLifecycleState.paused && currentUser != null) {
      authService.markUserOffline(currentUser.uid);
    } else if (state == AppLifecycleState.resumed && currentUser != null) {
      userActivityDetected();
    }
  }

  @override
  Widget build(BuildContext context) {
    // init AuthService.
    final AuthService authService = AuthService(
      FirebaseAuth.instance,
    );

    //wrap app in gesture detector to detect user activity
    return GestureDetector(
      onTap: userActivityDetected,
      //actual app widget
      child: CupertinoApp(
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
                // Get user document
                final userDoc = FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid);

                // Check if user has a username
                return FutureBuilder<DocumentSnapshot>(
                    future: userDoc.get(),
                    builder: (context, userInfo) {
                      if (userInfo.hasData) {
                        final userData =
                            userInfo.data!.data() as Map<String, dynamic>?;

                        //if user has no username, go to username selection page
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
      ),
    );
  }
}
