import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../backend stuff/auth/authbloc.dart';
import '../backend stuff/auth/authevent.dart';
import '../backend stuff/auth/authservice.dart';

// Define Login widget which is a StatefulWidget to handle mutable states
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  LoginState createState() => LoginState();
}

// Define the state for the Login widget
class LoginState extends State<Login> {
  final AuthService authService = AuthService(
    FirebaseAuth.instance,
  );

  // Build the UI for the Login page
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: GestureDetector(
          child: const Text("Login"),
          onTap: () async {
            bool isSuccess = await authService.signInWithGoogle();
            if (isSuccess) {
              // ignore: use_build_context_synchronously
              context.read<AuthBloc>().add(UserLoggedIn());
              print("Login successful");
            }
          },
        ),
      ),
    );
  }
}
