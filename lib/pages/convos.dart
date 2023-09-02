import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/pages/userslist.dart';
import '../backend stuff/convolist/convolistbloc.dart';
import '../backend stuff/convolist/convolistevent.dart';
import '../backend stuff/convolist/convoliststate.dart' as blocstate;
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

  //stream for user profile picture
  Stream<String> streamUserProfilePic(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['profilepicture'] ?? '');
  }

  //get current user
  User user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConvoListBloc(user)..add(LoadConvoList()),
      child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Colors.transparent,
            //buttons on the left side of the top menu bar
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
                        builder: (context) =>
                            UsersList(currentUserUid: user.uid));
                  },
                ),
              ],
            ),

            //go to current user profile page
            trailing: GestureDetector(
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
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(snapshot.data!),
                    );
                  }
                },
              ),
            ),
          ),

          //convo list
          child: BlocBuilder<ConvoListBloc, blocstate.ConvoListState>(
            builder: (context, state) {
              if (state is blocstate.ConvoListLoaded) {
                List<QueryDocumentSnapshot> conversations =
                    (state).conversations;

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (BuildContext context, int index) {
                    QueryDocumentSnapshot conversationDoc =
                        conversations[index];
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
                                    'members':
                                        FieldValue.arrayRemove([user.uid])
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
              } else {
                return const SizedBox.shrink();
              }
            },
          )),
    );
  }
}
