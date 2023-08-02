import 'package:cloud_firestore/cloud_firestore.dart';
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
                middle: CircleAvatar(
                  backgroundImage:
                      NetworkImage('${userData['profilepicture']}'),
                ),
                trailing: Text('${userData['name']}'),
              ),
              child: const Center(child: Text('user profile')));
        }
      },
    );
  }
}
