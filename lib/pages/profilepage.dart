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

    // Initialize userDataStream here
    userDataStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots();
  }

  @override
  void dispose() {
    // You can add any other disposals if needed here
    super.dispose();
  }

  // Check if the user is online or was last seen less than 5 minutes ago
  bool isUserOnline(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) return false;

    // Check if 'isOnline' field exists, else use a default value
    final isOnline = data.containsKey('isOnline') ? data['isOnline'] : false;

    // Check if 'lastSeen' field exists, else use a default value
    final lastSeen =
        data.containsKey('lastSeen') ? data['lastSeen'] as Timestamp? : null;

    if (isOnline) return true;
    if (lastSeen == null) return false;

    final difference = DateTime.now().difference(lastSeen.toDate());
    return difference.inMinutes < 5;
  }

  bool isListeningToStream = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: isListeningToStream ? userDataStream : null,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data!.data() == null) {
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
                              // Stop listening to the stream
                              setState(() {
                                isListeningToStream = false;
                              });

                              // Create an instance of AuthService
                              AuthService authService =
                                  AuthService(FirebaseAuth.instance);

                              //use auth service signout fn
                              await authService.signOutUser();

                              //pop back to login page
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst == true);
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

                    //profile picture w/ streamed border color for online status
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
