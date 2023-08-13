import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/pages/login.dart';
import 'package:pleasepleasepleaseplease/pages/userslist.dart';
import '../backend stuff/authservice.dart';
import 'messagingpage.dart';
import 'convoinfo.dart';
import 'createconvo.dart';
import 'profilepage.dart';

class ConvoList extends StatefulWidget {
  const ConvoList({Key? key}) : super(key: key);

  @override
  ConvoListState createState() => ConvoListState();
}

class ConvoListState extends State<ConvoList> {
  String defaultConvoPic =
      "https://raw.githubusercontent.com/jumbyjumbo/images/main/groupchat.jpg";
  late final AuthService authService;

  @override
  void initState() {
    super.initState();
    authService = AuthService(FirebaseAuth.instance);
  }

  //stream for user profile picture
  Stream<String> streamUserProfilePic(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['profilepicture'] ?? '');
  }

  Future<String> getUserName(String uid) async {
    final userDocument =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDocument.data()?['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.transparent,
          );
        } else {
          User? user = snapshot.data;
          if (user != null) {
            return buildUserInterface(user, context);
          } else {
            // If the user is not logged in, navigate to the login page.
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => const Login()),
            );
            return const SizedBox
                .shrink(); // This won't actually render, since we're navigating away.
          }
        }
      },
    );
  }

  Widget buildUserInterface(User user, BuildContext context) {
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

//convo
    Widget convoInstance(
        Map<String, dynamic> convoData, String conversationId, String userId) {
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

      //get convo info

      //prioritize custom convo pic,
      //then last sent picture message,
      // then other user profile pic,
      // then default convo pic
      Future<Map<String, String>> setConvoPicAndName(
          Map<String, dynamic> convoData, String userId) async {
        // get convo picture and name and set to default if null
        String convoPicUrl = convoData['convoPicture'] ?? defaultConvoPic;
        String convoName = convoData['name'] ?? 'new group chat';

        // If there is a custom convo picture, return it
        if (convoPicUrl != defaultConvoPic) {
          return {'convoPicUrl': convoPicUrl, 'convoName': convoName};
        } else {
          // get the last sent picture message if any
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('conversations')
              .doc(conversationId)
              .collection("messages")
              .where('type', isEqualTo: 'image')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          // If there is a picture message, get the last sent picture URL
          if (querySnapshot.docs.isNotEmpty) {
            String lastSentPictureUrl =
                querySnapshot.docs[0]['content'] ?? defaultConvoPic;
            convoPicUrl = lastSentPictureUrl;
          } else if (convoData['members'].length == 2) {
            // If there are only 2 members and no picture message, get the other user's profile picture and name
            String otherUserId = convoData['members'][0] == userId
                ? convoData['members'][1]
                : convoData['members'][0];

            DocumentSnapshot otherUserDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();

            convoPicUrl = otherUserDoc['profilepicture'] ?? defaultConvoPic;
            convoName = otherUserDoc['name'] ?? 'Unknown User';
          }

          return {'convoPicUrl': convoPicUrl, 'convoName': convoName};
        }
      }

      //return convo widget
      return Padding(
        padding: EdgeInsets.all(
          screenHeightUnit,
        ),

        //convo instance display
        child: FutureBuilder<Map<String, String>>(
          future: setConvoPicAndName(convoData, userId),
          builder: (context, snapshot) {
            //if snapshot is loading or has no data, show nothing
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return const SizedBox();
            }

            //get convo picture and name
            String convoPicDisplayed =
                snapshot.data?['convoPicUrl'] ?? defaultConvoPic;
            String convoNameDisplayed = snapshot.data?['convoName'] ?? 'convo';

            // Get the "hasread" field from the conversation data
            List<String> hasReadUsers =
                convoData['hasread']?.cast<String>() ?? [];

            // Check if the current user has read the message
            bool userHasRead = hasReadUsers.contains(userId);

            //show convo instance
            return Row(
              children: [
                //convo picture

                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: userHasRead
                        ? null
                        : Border.all(
                            color: Colors.green, // Border color
                            width: 2, // Border width
                          ),
                  ),
                  child: CircleAvatar(
                    radius: screenHeightUnit * 4,
                    backgroundColor: Colors.transparent,
                    backgroundImage: NetworkImage(convoPicDisplayed),
                  ),
                ),

                //spacing
                SizedBox(
                  width: screenHeightUnit * 2,
                ),

                //convo name and last msg
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convoNameDisplayed,
                        style: chatTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: chatTextStyle.fontSize! * 1.3,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      // last message
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(conversationId)
                            .collection("messages")
                            .doc(convoData['lastMessage'])
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              convoData['lastMessage'] == null ||
                              !snapshot.hasData) {
                            //show nothing
                            return Container(color: Colors.transparent);
                          }

                          // Get the last message data
                          Map<String, dynamic> lastMessageData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          // Return a text widget with the last message's content, sender and timestamp

                          // Get how long ago the last msg was sent
                          final int secondsAgo = DateTime.now()
                              .difference(lastMessageData['timestamp'].toDate())
                              .inSeconds;

                          // Inside the StreamBuilder for the last message
                          return Row(
                            children: [
                              FutureBuilder<String>(
                                future: getUserName(lastMessageData['sender']),
                                builder: (BuildContext context,
                                    AsyncSnapshot<String> snapshot) {
                                  //define the content of the message to display
                                  String content;
                                  if (lastMessageData['type'] == 'image') {
                                    content = 'sent a picture';
                                  } else {
                                    content = lastMessageData['content'];
                                    if (content.length > 20) {
                                      content =
                                          '${content.substring(0, 20)}...';
                                    }
                                  }

                                  String prefix = (convoData['members'].length >
                                              2 &&
                                          snapshot.hasData &&
                                          lastMessageData['sender'] != userId)
                                      ? "${snapshot.data}: "
                                      : "";

                                  // Display the last message with the prefix in bold
                                  return RichText(
                                    text: TextSpan(
                                      style: chatTextStyle.copyWith(
                                        color: userHasRead
                                            ? Colors.grey
                                            : CupertinoTheme.of(context)
                                                .primaryColor,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: prefix,
                                          style: chatTextStyle.copyWith(
                                            fontWeight: userHasRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: content,
                                          style: chatTextStyle.copyWith(
                                            fontWeight: userHasRead
                                                ? FontWeight.normal
                                                : FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Text(
                                "  •  ${secondsAgo < 10 ? "just now" : GetTimeAgo.parse(lastMessageData['timestamp'].toDate())}",
                                style: chatTextStyle.copyWith(
                                  color: userHasRead ? Colors.grey : null,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return CupertinoPageScaffold(
      //top menu bar
      navigationBar: CupertinoNavigationBar(
        //buttons on the right side of the top menu bar
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //new convo button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.plus_app_fill,
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
                CupertinoIcons.person_add_solid,
              ),
              onPressed: () {
                //show modal bottom sheet: add to convo (friends list)
                showCupertinoModalBottomSheet(
                    context: context,
                    builder: (context) => UsersList(currentUserUid: user.uid));
              },
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //profile button
            GestureDetector(
              onTap: () {
                // Go to profile page
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => ProfilePage(
                            userId: user.uid,
                          )),
                );
              },
              child: StreamBuilder<String>(
                stream: streamUserProfilePic(user.uid),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    return CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(snapshot.data!),
                    );
                  }
                },
              ),
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

              return GestureDetector(
                onTap: () {
                  // Open conversation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Messagingpage(
                        conversationId: conversationDoc.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  //border
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Slidable(
                    key: Key(conversationDoc.id),

                    //options on the left of convo (pin, settings page)
                    startActionPane: ActionPane(
                      extentRatio: 0.2,
                      motion: const ScrollMotion(),
                      children: <SlidableAction>[
                        //get convo info
                        SlidableAction(
                          //same as app theme primary color
                          backgroundColor:
                              CupertinoTheme.of(context).primaryColor,
                          icon: CupertinoIcons.info_circle_fill,
                          onPressed: (context) {
                            //open convo info page
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return ConvoInfoPage(
                                  conversationId: conversations[index].id,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    //options on the right of convo (archive, leave,)
                    endActionPane: ActionPane(
                      extentRatio: 0.2,
                      motion: const ScrollMotion(),
                      children: <SlidableAction>[
                        //leave convo
                        SlidableAction(
                          backgroundColor: Colors.red,
                          icon: CupertinoIcons
                              .person_crop_circle_fill_badge_xmark,
                          onPressed: (context) {
                            // remove current user from the conversation
                            FirebaseFirestore.instance
                                .collection('conversations')
                                .doc(conversationDoc.id)
                                .update({
                              'members': FieldValue.arrayRemove([user.uid])
                            });
                          },
                        ),
                      ],
                    ),

                    //convo widget
                    child: convoInstance(
                      conversationData,
                      conversationDoc.id,
                      user.uid,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
