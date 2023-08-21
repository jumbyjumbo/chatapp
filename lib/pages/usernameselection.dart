import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../backend stuff/auth/authbloc.dart';
import '../backend stuff/auth/authevent.dart';
import 'convos.dart';

class UsernameSelection extends StatefulWidget {
  const UsernameSelection({super.key});

  @override
  UsernameSelectionState createState() => UsernameSelectionState();
}

class UsernameSelectionState extends State<UsernameSelection> {
  //username controller for textfield
  final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //username textfield
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: CupertinoTextField(
                controller: usernameController,

                decoration: BoxDecoration(
                  color:
                      CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),

                //refuse whitespaces
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                //limit username length
                maxLength: 32,

                placeholder: 'Choose a unique username',
                padding: const EdgeInsets.all(16),
              ),
            ),

            //confirmation button
            CupertinoButton(
              child: const Text('Confirm'),
              onPressed: () async {
                // Get the username from the textfield
                String username = usernameController.text;
                // Get the current user
                User? currentUser = FirebaseAuth.instance.currentUser;

                if (username.isNotEmpty) {
                  // Check if the username already exists
                  final usernameDoc = await FirebaseFirestore.instance
                      .collection('usernames')
                      .doc(username)
                      .get();

                  //if username doesn't exist
                  if (!usernameDoc.exists) {
                    // Username is unique; create it in the usernames collection
                    await FirebaseFirestore.instance
                        .collection('usernames')
                        .doc(username)
                        .set({'uid': currentUser?.uid});

                    // Update the user's document in the users collection with the username
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .set({'username': username}, SetOptions(merge: true));

                    // Inform the AuthBloc that the user has logged in
                    // ignore: use_build_context_synchronously
                    context.read<AuthBloc>().add(UserLoggedIn());
                  } else {
                    //if username exists, show alert
                    // ignore: use_build_context_synchronously
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: const Text('username already exists'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('ok'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
