import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../backend stuff/authservice.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // Stream user's data
  late Stream<DocumentSnapshot<Object>> userDataStream;

  @override
  void initState() {
    super.initState();
  }

  // Check if the user is online or was last seen less than 5 minutes ago
  bool isUserOnline(DocumentSnapshot snapshot) {
    if (snapshot.data() == null) return false;
    final isOnline = snapshot.get('isOnline') ?? false;
    final lastSeen = snapshot.get('lastSeen') as Timestamp?;
    if (isOnline) return true;
    if (lastSeen == null) return false;
    final difference = DateTime.now().difference(lastSeen.toDate());
    return difference.inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userDataStream,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        //get user data
        Map<String, dynamic> userData =
            snapshot.data!.data() as Map<String, dynamic>;

        // get user's friends
        List<String> friends = List<String>.from(userData['friends'] ?? []);

        // Decide the border color based on user's online status
        Color borderColor =
            isUserOnline(snapshot.data!) ? Colors.green : Colors.grey;

        return CupertinoPageScaffold(
            //app bar
            navigationBar: CupertinoNavigationBar(
                //display user name
                middle: FittedBox(
                  child: Text(
                    '${userData['username']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
                            onPressed: () async {
                              // Create an instance of AuthService
                              AuthService authService =
                                  AuthService(FirebaseAuth.instance);

                              //use auth service signout fn
                              await authService.signOutUser();

                              //pop back to login page
                              // Pop all routes and go back to the root
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                          )
                        : const SizedBox.shrink()),

            //user profile
            child: Column(
              //align at the bottom of screen
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //profile picture + user stats
                Row(
                  children: [
                    //nb of friends + convos
                    Expanded(
                      child: Row(
                        children: [
                          //nb of friends
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${friends.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Friends',
                                ),
                              ],
                            ),
                          ),

                          //nb of convos
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${userData['convos'].length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Convos',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    //profile picture
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor, // Use dynamic border color
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          maxRadius: 40,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              NetworkImage(userData['profilepicture']),
                        ),
                      ),
                    ),
                    //nb of posts + messages
                    const Expanded(
                      child: Row(
                        children: [
                          //nb of messages
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Messages',
                                ),
                              ],
                            ),
                          ),
                          //nb of posts
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Posts',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                //user name
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${userData['name']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                //user bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${userData['bio']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // friends list
                Container(
                  height: 60,
                  // Border
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                      top: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),

                  // List of friends
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    itemBuilder: (BuildContext context, int index) {
                      return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friends[index])
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> friendSnapshot) {
                          if (friendSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              !friendSnapshot.hasData) {
                            return const SizedBox();
                          } else {
                            String profilePicture =
                                friendSnapshot.data!.get('profilepicture');
                            return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: FittedBox(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                              userId: friends[index]),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      foregroundImage:
                                          NetworkImage(profilePicture),
                                    ),
                                  ),
                                ));
                          }
                        },
                      );
                    },
                  ),
                )
              ],
            ));
      },
    );
  }
}
