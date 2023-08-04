import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late Stream<DocumentSnapshot> userDataStream;

  @override
  void initState() {
    super.initState();
    userDataStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userDataStream,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const CupertinoPageScaffold(
            child: SizedBox(),
          );
        } else {
          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;
          return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                  //display user name
                  middle: FittedBox(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage('${userData['profilepicture']}'),
                        ),
                        const SizedBox(width: 16),
                        Text('${userData['name']}'),
                      ],
                    ),
                  ),

                  //logout button if user profile is the current user's profile
                  trailing:
                      widget.userId == FirebaseAuth.instance.currentUser!.uid
                          ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.square_arrow_right,
                              ),
                              onPressed: () {
                                //logout
                                FirebaseAuth.instance.signOut();
                                //pop to login page
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst == true);
                              },
                            )
                          : const SizedBox.shrink()),
              child: const Center(child: Text('user profile')));
        }
      },
    );
  }
}
