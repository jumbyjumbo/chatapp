import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:async/async.dart';
import '../backend stuff/convoinstance/convoinstancebloc.dart';
import '../backend stuff/convoinstance/convoinstancestate.dart';
import 'convostatusdot.dart';

class ConvoInstance extends StatelessWidget {
  final Map<String, dynamic> convoData;
  final String conversationId;
  final String userId;

  const ConvoInstance({
    super.key,
    required this.convoData,
    required this.conversationId,
    required this.userId,
  });

  //get list of users for dot online status
  Stream<List<Map<String, dynamic>>> membersDataStream(
      List<String> memberIds, String currentUserId) {
    // Remove the current user from the list
    List<String> otherMembers =
        memberIds.where((userId) => userId != currentUserId).toList();

    // Create a list of streams of the other members' data
    List<Stream<DocumentSnapshot>> userStreams = otherMembers
        .map((userId) => FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots())
        .toList();

    return StreamZip<DocumentSnapshot>(userStreams).map((listOfUserDocs) {
      return listOfUserDocs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: BlocBuilder<ConvoInstanceBloc, ConvoInstanceState>(
        builder: (context, state) {
          if (state is ConvoInstanceInitial) {
            return Row(
              children: [
                //convo picture
                Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent, // Border color
                        width: 2, // Border width
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.transparent,
                    )),

                //spacing
                const SizedBox(
                  width: 8,
                ),

                //convo name and last msg
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("",
                          style: TextStyle(
                            fontSize: 18,
                          )),
                      SizedBox(
                        height: 8,
                      ),
                      // last message
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is ConvoInstanceLoaded) {
            return Row(
              children: [
                //convo picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(state.convoPicUrl),
                    ),
                    Positioned(
                        right: 4,
                        bottom: 4,
                        //status dot to check if a member is online
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: membersDataStream(
                              convoData['members'].cast<String>(), userId),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ConvoStatusDot(
                                  membersData: snapshot.data!);
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        )),
                  ],
                ),

                //spacing
                const SizedBox(
                  width: 8,
                ),

                //convo name and last msg
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //convo name
                      Text(
                        state.convoName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: state.isLastMessageRead
                              ? Colors.grey
                              : CupertinoTheme.of(context).primaryColor,
                        ),
                      ),

                      //spacing
                      const SizedBox(
                        height: 8,
                      ),

                      //last message
                      Text(
                        state.lastMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: state.isLastMessageRead
                              ? Colors.grey
                              : CupertinoTheme.of(context).primaryColor,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
