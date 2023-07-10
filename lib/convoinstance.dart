import 'package:dart_openai/dart_openai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

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
  //focus node for the message text field
  late FocusNode focusNode;
  //controller for the message text field
  final TextEditingController msgController = TextEditingController();

  //on init, get the current user
  @override
  void initState() {
    super.initState();
    //get the current user
    user = FirebaseAuth.instance.currentUser!;
    focusNode = FocusNode();
  }

  // 2. UI
  @override
  Widget build(BuildContext context) {
    //page scaffold
    return CupertinoPageScaffold(
      //top navigation bar
      navigationBar: CupertinoNavigationBar(
        //display conversation's name
        middle: Text(widget.conversationData['name']),
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
            //raw keyboard listener to listen for the enterv key
            child: RawKeyboardListener(
              focusNode: focusNode, //focus node for the text field
              onKey: (RawKeyEvent event) {
                //if the user presses enter, we send the message
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event.isKeyPressed(LogicalKeyboardKey.enter)) {
                  //if shift key is pressed, skip line
                  if (event.isShiftPressed) {
                    //move the cursor to the end of the text field
                    msgController.selection = TextSelection.fromPosition(
                        TextPosition(offset: msgController.text.length));
                  } else {
                    //if shift key is not pressed, we send the message
                    sendMessage();
                  }
                }
              },

              //text field
              child: CupertinoTextField(
                //handle the msg content to be sent by current user
                controller: msgController,
                placeholder: "Send a message...",
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  //border around the text field
                  border: Border.all(
                    color: CupertinoColors.inactiveGray,
                    width: 0.1,
                  ),
                ),
                maxLines: 10,
                minLines: 1,
                maxLength: 300,
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

    // Get the chatbot's response
    OpenAIChatCompletionModel chatbotResponse =
        await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: msgContext,
      maxTokens: 500,
      temperature: 0.2,
    );

    //send the generated response
    sendBotResponse(chatbotResponse.choices[0].message.content);
  }
}
