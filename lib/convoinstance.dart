import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/convosettings.dart';
import 'package:pleasepleasepleaseplease/uiFX.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'uploadimageweb.dart';

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

        //convo name + convo settings/info tab button
        middle: CupertinoButton(
          padding: EdgeInsets.zero,
          child: StreamBuilder(
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

          // check if the content is an image URL
          Widget contentWidget;
          if (data['type'] == 'image') {
            print("Image URL: ${data['content']}");
            contentWidget = Image.network(
              data['content'],
              fit: BoxFit.cover,
            );
          } else {
            contentWidget = Text(
              data['content'],
              softWrap: true,
              maxLines: 10,
            );
          }

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
                      //message sender's name
                      Text(
                        data['senderName'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      //message content
                      contentWidget,
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList();

        //add extra space at the end of messages
        messageWidgets.insert(
            0, const Padding(padding: EdgeInsets.symmetric(vertical: 30)));

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: value
                      ? ImageSelect(
                          conversationId: widget.conversationId,
                          user: user,
                        )
                      : CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: sendTextMessage,
                          child: const Text('Send',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                );
              }),
        ),
      ),
    );
  }

//send a msg from the current user
  Future<void> sendTextMessage() async {
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
        'type': 'text',
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

//image selection button to send images as messages
class ImageSelect extends StatelessWidget {
  const ImageSelect(
      {Key? key, required this.conversationId, required this.user})
      : super(key: key);

  final String conversationId;
  final User user;

  Future<String> uploadImageToFirebase(XFile imageFile) async {
    if (kIsWeb) {
      return await uploadImageToFirebaseWeb(conversationId, imageFile);
    } else {
      FirebaseStorage storage = FirebaseStorage.instance;

      // Convert the XFile to a File
      File file = File(imageFile.path);

      // Extract the extension from the imageFile
      String fileExtension = path.extension(imageFile.path);

      try {
        await storage
            .ref(
                'conversations/$conversationId/${path.basename(imageFile.path)}$fileExtension')
            .putFile(file);

        // Return the download URL
        String downloadURL = await storage
            .ref(
                'conversations/$conversationId/${path.basename(imageFile.path)}$fileExtension')
            .getDownloadURL();
        return downloadURL;
      } on FirebaseException catch (e) {
        print(e);
        return "";
      }
    }
  }

  Future<void> createImageMsg(String imageUrl) async {
    final DateTime now = DateTime.now();

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;

    FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'type': 'image',
      'sender': user.uid,
      'senderName': userData['name'],
      'senderProfilePicture': userData['profilepicture'],
      'content': imageUrl, // The content is now an image URL
      'timestamp': now,
    }).then((value) {
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': value.id,
        'lastmessagetimestamp': now,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Icon(CupertinoIcons.photo),
      onPressed: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          String imageUrl = await uploadImageToFirebase(
              image); // Upload the image to Firebase
          if (imageUrl.isNotEmpty) {
            // Check if the upload was successful
            await createImageMsg(
                imageUrl); // Create a new image message with the download URL
          }
        }
      },
    );
  }
}
