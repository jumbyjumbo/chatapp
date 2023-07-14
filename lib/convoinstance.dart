import 'package:dart_openai/dart_openai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/convosettings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  //signed in user
  late User user;
  //controller for the message text field
  final TextEditingController msgController = TextEditingController();

  //on init, get the current user
  @override
  void initState() {
    super.initState();
    //get the current user
    user = FirebaseAuth.instance.currentUser!;
  }

  //free up memory
  @override
  void dispose() {
    // Always call super.dispose() first
    super.dispose();
    // Dispose of the text controller when the state is destroyed.
    msgController.dispose();
  }

  // 2. UI
  @override
  Widget build(BuildContext context) {
    //page scaffold
    return CupertinoPageScaffold(
      //top navigation bar
      navigationBar: CupertinoNavigationBar(
        //convo name
        middle: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('globalConvos')
              .doc(widget.conversationId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              return Text(snapshot.data?['name']);
            } else {
              return const Text('');
            }
          },
        ),
        //convo buttons
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.gear),
              onPressed: () {
                //show convo settings ui
                showCupertinoModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return ConversationSettings(
                      conversationId: widget.conversationId,
                      conversationData: widget.conversationData,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      //body (messages list/column)
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
        //get user data from firestore with his uid
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

        //actual message list
        return ListView(
          reverse: true,
          //map each message to a widget
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return StreamBuilder<DocumentSnapshot>(
              //get the msg sender's data
              stream: getUserData(data['sender']),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                //if snapshot is loading or has no data, show nothing
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  //show nothing
                  return Container(
                    color: Colors.transparent,
                  );
                }

                //get user data
                Map<String, dynamic> userData =
                    snapshot.data!.data()! as Map<String, dynamic>;
                //message padding
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  //message row
                  child: Row(
                    children: [
                      //message sender's  profile picture
                      CircleAvatar(
                        backgroundImage: NetworkImage(userData[
                            'profilepicture']), //get the profile picture from the user data
                        backgroundColor: Colors.transparent, // no pp background
                      ),
                      const SizedBox(
                          width:
                              10), // gives some spacing between the pp and the message content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              //message sender's name
                              userData['name'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            //message content
                            Text(
                              data['content'],
                              softWrap: true,
                              maxLines: 10,
                            ),
                          ],
                        ),
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
      //padding for the text field and send button
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            //raw keyboard listener to listen for the enter key
            child: Container(
              decoration: BoxDecoration(
                //border around text field
                border: Border.all(
                  color: CupertinoColors.systemGrey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: CupertinoTextField(
                  decoration: const BoxDecoration(
                    border: null,
                  ),
                  //handle the msg content to be sent by current user
                  controller: msgController,
                  placeholder: "Send a message...",
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  maxLines: 10,
                  minLines: 1,
                  maxLength: 1000,
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
        }).then((value) {
          //generate response from chatbot
          generateChatbotResponse();
        });
      });

      //clear the chat text field
      msgController.clear();
    }
  }

//send chatbot messages
  Future<void> sendBotResponse(String message) async {
    final DateTime now = DateTime.now(); // creates a new timestamp

    //add the message to the conversation
    FirebaseFirestore.instance
        .collection('globalConvos')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
      'sender': 'chatbot',
      'content': message,
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
  }

  Future<void> generateChatbotResponse() async {
    // Fetch all messages from Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('globalConvos')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();

    // Generate context messages from Firestore messages
    List<OpenAIChatCompletionChoiceMessageModel> msgContext =
        snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
      //role is system is msg was sent by chatbot, otherwise its user
      OpenAIChatMessageRole role = data['sender'] == "chatbot"
          ? OpenAIChatMessageRole.assistant
          : OpenAIChatMessageRole.user;
      return OpenAIChatCompletionChoiceMessageModel(
        role: role,
        content: data['content'],
      );
    }).toList();

    // URL of your Firebase function
    const url =
        "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/get_openai_completion";

    // Making a POST request
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{'messages': msgContext}),
    );

    // If the server returns a 200 OK response, parse the JSON.
    if (response.statusCode == 200) {
      // Get the chatbot's response
      String chatbotResponse = jsonDecode(response.body);

      // Send the generated response
      sendBotResponse(chatbotResponse);
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to generate chatbot response');
    }
  }
}
