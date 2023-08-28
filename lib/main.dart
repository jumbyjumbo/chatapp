import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'backend stuff/auth/authbloc.dart';
import 'backend stuff/auth/authevent.dart';
import 'backend stuff/auth/authstate.dart';
import 'backend stuff/convolist/convolistbloc.dart';
import 'backend stuff/firebase_options.dart';
import 'backend stuff/auth/authservice.dart';
import 'pages/login.dart';
import 'pages/convos.dart';
import 'pages/usernameselection.dart';

void main() async {
  // Make sure widgets load before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService(FirebaseAuth.instance);
  Timer? _inactivityTimer;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();

    _lifecycleListener = AppLifecycleListener(
      onShow: _markUserAsOnline,
      onResume: _markUserAsOnline,
      onHide: _startInactivityTimer,
      onInactive: _startInactivityTimer,
      onPause: _startInactivityTimer,
    );
  }

  void _markUserAsOnline() {
    _inactivityTimer?.cancel(); // Cancel any existing timer
    // Mark user as online using the AuthService
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _authService.markUserOnline(currentUser.uid);
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel(); // Cancel any existing timer
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      // Mark user as offline using the AuthService
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _authService.markUserOffline(currentUser.uid);
      }
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  //bloc
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthBloc(authService: _authService)..add(AppStarted()),
      child: CupertinoApp(
        title: "Flow",
        theme: CupertinoThemeData(
          primaryColor: CupertinoTheme.brightnessOf(context) == Brightness.light
              ? CupertinoColors.black
              : CupertinoColors.white,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            //auth states and what to do with them
            switch (state.runtimeType) {
              case Unauthenticated:
                return const Login();
              case UsernameNotSet:
                return const UsernameSelection();
              case Authenticated:
                return BlocProvider(
                  create: (context) =>
                      ConvoListBloc(FirebaseAuth.instance.currentUser!),
                  child: const ConvoList(),
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
