import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/userslist.dart';

import 'authservice.dart';
import 'convoinstance.dart';
import 'friendslist.dart';

class ConvoList extends StatefulWidget {
  const ConvoList({Key? key}) : super(key: key);

  @override
  ConvoListState createState() => ConvoListState();
}

class ConvoListState extends State<ConvoList> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(FirebaseAuth.instance);
  }

  Future<String> getUserName(String uid) async {
    final userDocument =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDocument.data()?['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          User? user = snapshot.data;
          if (user != null) {
            return _buildUserInterface(user, context);
          } else {
            // If the user is not logged in, navigate to the login page.
            Navigator.of(context).pushReplacementNamed('/login');
            return const SizedBox
                .shrink(); // This won't actually render, since we're navigating away.
          }
        }
      },
    );
  }

  Widget _buildUserInterface(User user, BuildContext context) {
// get screen width and height
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    //get 1% of screen width and height for sizing widgets
    // ignore: unused_local_variable
    double screenWidthUnit = screenWidth * 0.01;
    // ignore: unused_local_variable
    double screenHeightUnit = screenHeight * 0.01;

    Stream<QuerySnapshot> conversationsStream = FirebaseFirestore.instance
        .collection('conversations')
        .where('members',
            arrayContains: user
                .uid) // Filter conversations where the user is a participant
        .orderBy('lastmessagetimestamp',
            descending:
                true) // Order conversations by last message timestamp in descending order
        .snapshots();

    return CupertinoPageScaffold(
      //top menu bar
      navigationBar: CupertinoNavigationBar(
        //display logged in user's name in the left center in bold, large font
        leading: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            //if snapshot is loading or has no data, show nothing
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              //show nothing
              return const SizedBox.shrink();
            }
            //display user's name
            return FittedBox(
              fit: BoxFit.contain,
              child: Text(snapshot.data!['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            );
          },
        ),
        //buttons on the right side of the top menu bar
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //new convo button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.paperplane_fill,
                color: CupertinoColors.activeBlue,
              ),
              onPressed: () {
                //show modal bottom sheet: add to convo (friends list)
                showCupertinoModalBottomSheet(
                    context: context,
                    builder: (context) => FriendsList(
                          userId: user.uid,
                        ));
              },
            ),

            //add friends button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.bolt_fill,
                color: CupertinoColors.activeBlue,
              ),
              onPressed: () {
                //show modal bottom sheet: add to convo (friends list)
                showCupertinoModalBottomSheet(
                    context: context,
                    builder: (context) => UsersList(currentUserUid: user.uid));
              },
            ),

            //profile button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.profile_circled,
                color: CupertinoColors.activeBlue,
              ),
              onPressed: () {
                // route to profile page
                Navigator.of(context).pushNamed('/profile');
              },
            ),

            //logout button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.square_arrow_right,
                color: CupertinoColors.activeBlue,
              ),
              onPressed: () {
                //logout
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      //convo list
      child: StreamBuilder<QuerySnapshot>(
        stream: conversationsStream,
        builder: (context, snapshot) {
          //if snapshot is loading or has no data, show nothing
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            //show nothing
            return const SizedBox.shrink();
          }

          // Get the documents of the conversations
          List<QueryDocumentSnapshot> conversations = snapshot.data!.docs;

          //convo list
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (BuildContext context, int index) {
              QueryDocumentSnapshot conversationDoc = conversations[index];
              Map<String, dynamic> conversationData =
                  conversationDoc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(conversationDoc.id),
                child: GestureDetector(
                  onTap: () {
                    // Open conversation
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConvoInstance(
                          conversationId: conversationDoc.id,
                          conversationData: conversationData,
                        ),
                      ),
                    );
                  },
                  child: _buildConvoWidget(
                    conversationData,
                    conversationDoc.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  //convo
  Widget _buildConvoWidget(
      Map<String, dynamic> convoData, String conversationId) {
    // get screen width and height
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    //get 1% of screen width and height for sizing widgets
    double screenWidthUnit = screenWidth * 0.01;
    double screenHeightUnit = screenHeight * 0.01;
    //mobile font size (minimum font size)
    double mobileFontSize = 15;

    //chat text style/size
    TextStyle chatTextStyle = TextStyle(
      fontSize: screenHeight > screenWidth
          ? mobileFontSize
          : (screenWidthUnit * 1.25 < mobileFontSize
              ? mobileFontSize
              : screenWidthUnit * 1.25),
    );
    //return convo widget
    return Container(
      //border
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      //padding
      child: Padding(
        padding: EdgeInsets.all(
          screenHeightUnit,
        ),

        //convo instance display
        child: Row(
          children: [
            CircleAvatar(
                radius: screenHeightUnit * 4,
                backgroundColor: Colors.transparent,
                backgroundImage: NetworkImage(
                  convoData['convoPicture'],
                )),
            SizedBox(
              width: screenHeightUnit * 2,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convoData['name'],
                  style: chatTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: chatTextStyle.fontSize! * 1.1,
                  ),
                ),
                // StreamBuilder to display the last message
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversationId)
                      .collection("messages")
                      .doc(convoData['lastMessage'])
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        convoData['lastMessage'] == null ||
                        !snapshot.hasData) {
                      //show nothing
                      return Container(color: Colors.transparent);
                    }

                    // Get the last message data
                    Map<String, dynamic> lastMessageData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    // Return a text widget with the last message's content, sender and timestamp
                    return Row(
                      children: [
                        FutureBuilder<String>(
                          future: getUserName(lastMessageData['sender']),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            String content = lastMessageData['content'];
                            if (content.length > 20) {
                              content = '${content.substring(0, 20)}...';
                            }
                            // If there are more than 2 members in the conversation, prepend the sender's name to the message content.
                            String prefix = (convoData['members'].length > 2 &&
                                    snapshot.hasData)
                                ? "${snapshot.data}:"
                                : "";
                            return Text(
                              "$prefix$content",
                              style: chatTextStyle.copyWith(
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        // Display the timestamp in "time ago" format
                        Text(
                          "  •  ${GetTimeAgo.parse(lastMessageData['timestamp'].toDate())}",
                          style: chatTextStyle.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
