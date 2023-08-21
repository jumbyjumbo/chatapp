import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/pages/login.dart';
import 'package:pleasepleasepleaseplease/pages/userslist.dart';
import '../backend stuff/auth/authservice.dart';
import '../ui stuff/convoinstance.dart';
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Your navigation action
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (context) => const Login()),
              );
            });

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
                  elevation: 20,
                  context: context,
                  builder: (context) => FriendsList(
                    userId: user.uid,
                  ),
                );
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
                    child: ConvoInstance(
                      convoData: conversationData,
                      conversationId: conversationDoc.id,
                      userId: user.uid,
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
