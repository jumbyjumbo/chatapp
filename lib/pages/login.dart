import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../backend stuff/authservice.dart';

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
            // Here we call the signInWithGoogle method from our AuthService
            await authService.signInWithGoogle();
          },
        ),
      ),
    );
  }
}
