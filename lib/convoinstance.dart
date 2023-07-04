import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Declaration of the ConvoInstance widget and its properties.
class ConvoInstance extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversationData;

  const ConvoInstance({
    Key? key,
    required this.conversationId,
    required this.conversationData,
  }) : super(key: key);

  @override
  MessagesState createState() => MessagesState();
}

class MessagesState extends State<ConvoInstance> {
  //currently logged in user
  late User user;

  //controller for the message text field
  final TextEditingController msgController = TextEditingController();

  //on init, get the current user
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
  }

  // 2. UI
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.conversationData['name']),
      ),
      child: Column(
        children: [
          Expanded(
            child: buildMessageList(),
          ),
          buildMessageSender(),
        ],
      ),
    );
  }

// 3. Logic for interacting with the database
  Stream<DocumentSnapshot> getUserData(String userId) {
    return Stream.fromFuture(
        FirebaseFirestore.instance.collection('users').doc(userId).get());
  }

  //build the list of messages
  Widget buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      //stream ConvoInstance of conversation from firestore
      stream: FirebaseFirestore.instance
          .collection('globalConvos')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),

      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        //if snapshot is loading or has no data, show nothing
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          //show nothing
          return const SizedBox.shrink();
        }
        return ListView(
          reverse: true,
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return StreamBuilder<DocumentSnapshot>(
              stream: getUserData(data['sender']),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                //if snapshot is loading or has no data, show nothing
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  //show nothing
                  return Container(color: Colors.transparent);
                }
                //get user data
                Map<String, dynamic> userData =
                    snapshot.data!.data()! as Map<String, dynamic>;
                //build message
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            NetworkImage(userData['profilepicture']),
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(
                          width:
                              10), // gives some spacing between the avatar and the texts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(data['content']),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

//build the chat text field and send button
  Widget buildMessageSender() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: CupertinoTextField(
              controller: msgController,
              placeholder: "Send a message...",
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                  color: CupertinoColors.inactiveGray,
                  width: 0.5,
                ),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: sendMessage,
            child: const Icon(CupertinoIcons.paperplane),
          ),
        ],
      ),
    );
  }

//send a msg from the current user
  void sendMessage() {
    if (msgController.text.isNotEmpty) {
      final DateTime now = DateTime.now(); // creates a new timestamp

      //add the message to the conversation
      FirebaseFirestore.instance
          .collection('globalConvos')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'sender': user.uid,
        'content': msgController.text,
        'timestamp': now,
      }).then((value) {
        //update the last message sent in the conversation
        FirebaseFirestore.instance
            .collection('globalConvos')
            .doc(widget.conversationId)
            .update({
          'lastMessage': value.id,
          'lastmessagetimestamp': now, // updates the lastmessagetimestamp field
        });
      });

      msgController.clear();
    }
  }
}
