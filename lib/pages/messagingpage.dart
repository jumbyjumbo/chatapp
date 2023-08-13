import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pleasepleasepleaseplease/pages/profilepage.dart';
import '/ui stuff/uifx.dart';
import 'convoinfo.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '/backend stuff/uploadimageweb.dart';

class Messagingpage extends StatefulWidget {
  final String conversationId;

  const Messagingpage({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  MessagesState createState() => MessagesState();
}

class MessagesState extends State<Messagingpage> {
  //signed in user
  late User user;

  //controller for the message text field
  final TextEditingController msgController = TextEditingController();
  ValueNotifier<bool> textFieldIsEmpty = ValueNotifier(true);

  //check if user has read the convo, add them if not
  Future<void> markUserHasRead() async {
    // Get the conversation document
    DocumentSnapshot convoDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    List<String> hasRead = List<String>.from(convoDoc['hasread'] ?? []);

    // If the user's ID is not in "hasread", add it
    if (!hasRead.contains(user.uid)) {
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'hasread': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  //on init, get the current user
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;

    // Add user to "viewing" when entering the page
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'viewing': FieldValue.arrayUnion([user.uid]),
    });

    //add user to has read list when entering the page
    markUserHasRead();
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

    // Remove user from "viewing" when leaving the page
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'viewing': FieldValue.arrayRemove([user.uid]),
    });
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
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return const SizedBox();
              } else {
                //get the convo data
                Map<String, dynamic> convoData =
                    snapshot.data!.data() as Map<String, dynamic>;

                if (convoData['name'] == 'new convo' &&
                    convoData['members'].length == 2) {
                  // Find the userId of the other user
                  String otherUserId = convoData['members']
                      .firstWhere((member) => member != user.uid);

                  // Fetch and return the name of the other user
                  return FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(),
                    builder:
                        (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData) {
                        return const SizedBox();
                      } else {
                        return FittedBox(
                            child: Text(snapshot.data!['name'].toString()));
                      }
                    },
                  );
                } else {
                  // Display the conversation name as usual
                  return FittedBox(child: Text(convoData['name']));
                }
              }
            },
          ),
          onPressed: () {
            //show convo settings ui
            showCupertinoModalBottomSheet(
              context: context,
              builder: (context) {
                return ConvoInfoPage(
                  conversationId: widget.conversationId,
                );
              },
            );
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            //show convo settings ui
            showCupertinoModalBottomSheet(
              context: context,
              builder: (context) {
                return ConvoInfoPage(
                  conversationId: widget.conversationId,
                );
              },
            );
          },
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .doc(widget.conversationId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return const SizedBox.shrink();
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage:
                          NetworkImage(snapshot.data?['convoPicture'])),
                );
              }
            },
          ),
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
      //stream of messages
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

          // check if the content is an image or text
          Widget contentWidget;

          //if the message is an image
          if (data['type'] == 'image') {
            contentWidget = LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16.0), // Change as needed
                  child: SizedBox(
                    //max height of image is 1/3 of the screen
                    height: MediaQuery.of(context).size.height / 3,
                    child: Image.network(
                      data['content'],
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                );
              },
            );
          } else if (data['type'] == 'text') {
            //if the message is text
            contentWidget = Text(
              data['content'],
              softWrap: true,
              maxLines: 10,
            );
          } else {
            //if the message is neither text nor image
            contentWidget = const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            //message row
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //message sender's profile picture
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(userId: data['sender']),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(data[
                        'senderProfilePicture']), //get the profile picture from the message data
                    backgroundColor: Colors.transparent, // no pp background
                  ),
                ),

                //spacing between profile picture ann message content
                const SizedBox(width: 8),

                //sender name + message content
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
                      const SizedBox(height: 4),
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

  //build the chatbox where the user writes and sends messages and pictures
  Widget buildMessageSender() {
    //listen to the text field and update the send button accordingly
    msgController.addListener(() {
      textFieldIsEmpty.value = msgController.text.isEmpty;
    });

    return Padding(
      padding: const EdgeInsets.all(8),
      child: BlurEffectView(
        blurAmount: 10,
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (RawKeyEvent event) {
            if (event.isShiftPressed &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              sendTextMessage();
            }
          },
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
            textInputAction: TextInputAction.newline,
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
                            pathToStore: "imagesSent",
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
      ),
    );
  }

//send a msg from the current user
  Future<void> sendTextMessage() async {
    // Trim right whitespace
    String trimmedMsg = msgController.text.trimRight();
    if (trimmedMsg.isNotEmpty) {
      final DateTime now = DateTime.now(); // creates a new timestamp

      //get the current user's data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;

      // Get the conversation document
      DocumentSnapshot convoDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();
      Map<String, dynamic> convoData = convoDoc.data()! as Map<String, dynamic>;

      // Get the list of users viewing the conversation
      List<String> viewing = List<String>.from(convoData['viewing'] ?? []);

      // Make sure the sender is included in the "hasread" list
      if (!viewing.contains(user.uid)) {
        viewing.add(user.uid);
      }

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
        'content': trimmedMsg,
        'timestamp': now,
      }).then((value) {
        //update the last message sent in the conversation
        FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .update({
          //store some info about the last message for ease of access
          'lastMessage': value.id,
          'lastmessagetimestamp': now,
          //the current user has read the message but remove everyone else
          'hasread': viewing,
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
      {Key? key,
      required this.conversationId,
      required this.user,
      required this.pathToStore})
      : super(key: key);

  final String conversationId;
  final User user;
  final String pathToStore;

  Future<String> uploadImageToFirebase(XFile imageFile) async {
    //the method is different in the browser
    //it uses html pkg which needs to be isolated from rest of code
    if (kIsWeb) {
      return await uploadImageToFirebaseWeb(
          conversationId, imageFile, pathToStore);
    } else {
      FirebaseStorage storage = FirebaseStorage.instance;

      // Convert the XFile to a File
      File file = File(imageFile.path);

      // Extract the extension from the imageFile
      String fileExtension = path.extension(imageFile.path);
      //write the full path of the image
      String fullPath =
          'conversations/$conversationId/$pathToStore/${path.basename(imageFile.path)}$fileExtension';

      //store the file at path
      await storage.ref(fullPath).putFile(file);

      // get the image's download URL
      String downloadURL = await storage.ref(fullPath).getDownloadURL();
      //return it
      return downloadURL;
    }
  }

  Future<void> createImageMsg(String imageUrl) async {
    final DateTime now = DateTime.now();

    //get the current user's data
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;

// Get the conversation document
    DocumentSnapshot convoDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get();
    Map<String, dynamic> convoData = convoDoc.data()! as Map<String, dynamic>;

    // Get the list of users viewing the conversation
    List<String> viewing = List<String>.from(convoData['viewing'] ?? []);

    // Make sure the sender is included in the "hasread" list
    if (!viewing.contains(user.uid)) {
      viewing.add(user.uid);
    }

    //add the message to the conversation
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
        //the current user has read the message but remove everyone else
        'hasread': viewing,
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
