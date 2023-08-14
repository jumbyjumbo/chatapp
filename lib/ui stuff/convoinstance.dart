import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';

class ConvoInstance extends StatefulWidget {
  final Map<String, dynamic> convoData;
  final String conversationId;
  final String userId;

  const ConvoInstance({
    super.key,
    required this.convoData,
    required this.conversationId,
    required this.userId,
  });

  @override
  State<ConvoInstance> createState() => ConvoInstanceState();
}

class ConvoInstanceState extends State<ConvoInstance> {
  // Set the conversation picture and name
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
      QuerySnapshot lastImageSentSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection("messages")
          .where('type', isEqualTo: 'image')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // If there is a picture message, get the last sent picture URL
      if (lastImageSentSnapshot.docs.isNotEmpty) {
        String lastSentPictureUrl =
            lastImageSentSnapshot.docs[0]['content'] ?? defaultConvoPic;
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

  String defaultConvoPic =
      "https://raw.githubusercontent.com/jumbyjumbo/images/main/groupchat.jpg";

  Future<String> getUserName(String uid) async {
    final userDocument =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDocument.data()?['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: FutureBuilder<Map<String, String>>(
        future: setConvoPicAndName(widget.convoData, widget.userId),
        builder: (context, snapshot) {
          //if snapshot is loading or has no data, show nothing
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
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
          }

          //get convo picture and name
          String convoPicDisplayed =
              snapshot.data?['convoPicUrl'] ?? defaultConvoPic;
          String convoNameDisplayed = snapshot.data?['convoName'] ?? 'convo';

          // Get the "hasread" field from the conversation data
          List<String> hasReadUsers =
              widget.convoData['hasread']?.cast<String>() ?? [];

          // Check if the current user has read the message
          bool userHasRead = hasReadUsers.contains(widget.userId);

          // Get the last message id
          String? lastMessageId = widget.convoData['lastmessage'] as String?;

          //show convo instance
          return Row(
            children: [
              //convo picture

              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: userHasRead
                      ? Border.all(
                          color: Colors.transparent, // Border color
                          width: 2, // Border width
                        )
                      : Border.all(
                          color: Colors.green, // Border color
                          width: 2, // Border width
                        ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.transparent,
                  backgroundImage: NetworkImage(convoPicDisplayed),
                ),
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
                    Text(
                      convoNameDisplayed,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: userHasRead
                            ? Colors.grey
                            : CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    // last message

                    // display last message
                    StreamBuilder(
                      //stream the last message's data
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(widget.conversationId)
                          .collection("messages")
                          .doc(lastMessageId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        //if snapshot is loading or has no data, show nothing
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            !snapshot.hasData ||
                            snapshot.data!.data() == null) {
                          return const Text(
                            "",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          );
                        } else {
                          // Get the last message data
                          Map<String, dynamic> lastMessageData =
                              snapshot.data!.data() as Map<String, dynamic>;

                          // Get how long ago the last msg was sent
                          int secondsAgo = DateTime.now()
                              .difference(lastMessageData['timestamp'].toDate())
                              .inSeconds;

                          //define the content of the message to display
                          String content;
                          if (lastMessageData['type'] == 'image') {
                            content = 'sent a picture';
                          } else {
                            content = lastMessageData['content'];
                            if (content.length > 20) {
                              content = '${content.substring(0, 20)}...';
                            }
                          }

                          return FutureBuilder<String>(
                            future: getUserName(lastMessageData['sender']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  !snapshot.hasData) {
                                return const Text(""); // or a loading indicator
                              }

                              // Get the last message sender's name
                              String senderName = snapshot.data ?? '';

                              //message sender displayed if group chat
                              String prefix =
                                  (widget.convoData['members'].length > 2 &&
                                          lastMessageData['sender'] !=
                                              widget.userId)
                                      ? "$senderName: "
                                      : "";

                              // Display the last message
                              return RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: userHasRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: userHasRead
                                        ? Colors.grey
                                        : CupertinoTheme.of(context)
                                            .primaryColor,
                                  ),
                                  children: [
                                    //message sender
                                    TextSpan(
                                      text: prefix,
                                    ),
                                    TextSpan(
                                      //message content
                                      text: content,
                                    ),
                                    //message timestamp
                                    TextSpan(
                                      text:
                                          "  •  ${secondsAgo < 10 ? "just now" : GetTimeAgo.parse(lastMessageData['timestamp'].toDate())}",
                                      style: TextStyle(
                                        color: userHasRead ? Colors.grey : null,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
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
}
