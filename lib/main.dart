import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'backend stuff/auth/authbloc.dart';
import 'backend stuff/auth/authevent.dart';
import 'backend stuff/auth/authstate.dart';
import 'backend stuff/firebase_options.dart';
import 'backend stuff/auth/authservice.dart';
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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService(FirebaseAuth.instance);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthBloc(authService: _authService)..add(AppStarted()),
      child: GestureDetector(
        onTap: () {
          // Here you can dispatch a BLoC event for user activity.
          // For example: context.read<AuthBloc>().add(UserActivityDetected());
        },
        child: CupertinoApp(
          title: "Flow",
          theme: CupertinoThemeData(
            primaryColor:
                CupertinoTheme.brightnessOf(context) == Brightness.light
                    ? CupertinoColors.black
                    : CupertinoColors.white,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Unauthenticated) {
                return const Login();
              } else if (state is UsernameNotSet) {
                return const UsernameSelection();
              } else if (state is Authenticated) {
                return const ConvoList();
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
