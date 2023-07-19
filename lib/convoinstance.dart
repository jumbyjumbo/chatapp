import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/convosettings.dart';
import 'package:pleasepleasepleaseplease/uiFX.dart';

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
  ValueNotifier<bool> textFieldIsEmpty = ValueNotifier(true);

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

    //dispose of the text field listener
    textFieldIsEmpty.dispose();
  }

  // 2. UI
  @override
  Widget build(BuildContext context) {
    //page scaffold
    return CupertinoPageScaffold(
      //top navigation bar
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        //convo name
        middle: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('conversations')
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
      child: Stack(
        children: [
          buildMessageList(),
          Positioned(bottom: 0, left: 0, right: 0, child: buildMessageSender()),
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
  //build the list of messages
  Widget buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      //stream ConvoInstance of conversation from firestore
      stream: FirebaseFirestore.instance
          .collection('conversations')
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
        var messageWidgets =
            snapshot.data!.docs.map((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            //message row
            child: Row(
              children: [
                //message sender's profile picture
                CircleAvatar(
                  backgroundImage: NetworkImage(data[
                      'senderProfilePicture']), //get the profile picture from the message data
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
                        data['senderName'],
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
        }).toList();

        messageWidgets.insert(
            0,
            const Padding(
                padding: EdgeInsets.symmetric(
                    vertical:
                        30)) // This is the extra space at the beginning of the list.
            );

        return ListView(
          reverse: true,
          // map each message to a widget
          children: messageWidgets,
        );
      },
    );
  }

  Widget buildMessageSender() {
    //listen to the text field and update the send button accordingly
    msgController.addListener(() {
      textFieldIsEmpty.value = msgController.text.isEmpty;
    });

    return Padding(
      padding: const EdgeInsets.all(8),
      child: BlurEffectView(
        blurAmount: 10,
        child: CupertinoTextField(
          decoration: const BoxDecoration(
            border: null,
          ),
          controller: msgController,
          placeholder: "Message",
          placeholderStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: CupertinoColors.placeholderText),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.send,
          maxLines: 10,
          minLines: 1,
          maxLength: 1000,
          suffix: ValueListenableBuilder<bool>(
              valueListenable: textFieldIsEmpty,
              builder: (context, value, child) {
                return value
                    ? CupertinoButton(
                        child: const Icon(CupertinoIcons.photo),
                        onPressed: () async {
                          final ImagePicker _picker = ImagePicker();
                          final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            // On web, the image is a network-accessible URL
                            // Hence, use Image.network
                            if (kIsWeb) {
                              // Use the picked image
                              // Image.network(image.path);
                              print(image.path);
                            } else {
                              // On mobile platforms, use the image normally
                              // Image.file(File(image.path));
                              print(image.path);
                            }
                          }
                        },
                      )
                    : CupertinoButton(
                        onPressed: sendMessage,
                        child: const Text('Send',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      );
              }),
        ),
      ),
    );
  }

//send a msg from the current user
  Future<void> sendMessage() async {
    if (msgController.text.isNotEmpty) {
      final DateTime now = DateTime.now(); // creates a new timestamp

      //get the current user's data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;

      //add the message to the conversation
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'sender': user.uid,
        'senderName':
            userData['name'], // include the sender's name in the message data
        'senderProfilePicture': userData[
            'profilepicture'], // include the sender's profile picture in the message data
        'content': msgController.text,
        'timestamp': now,
      }).then((value) {
        //update the last message sent in the conversation
        FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .update({
          'lastMessage': value.id,
          'lastmessagetimestamp': now, // updates the lastmessagetimestamp field
        });
      });

      //clear the chat text field
      msgController.clear();
    }
  }
}
