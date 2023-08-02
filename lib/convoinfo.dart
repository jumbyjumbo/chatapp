import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path/path.dart' as path;
import 'uploadimageweb.dart';

class ConvoInfoPage extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversationData;

  const ConvoInfoPage(
      {Key? key, required this.conversationId, required this.conversationData})
      : super(key: key);

  @override
  ConvoInfoPageState createState() => ConvoInfoPageState();
}

class ConvoInfoPageState extends State<ConvoInfoPage> {
  //convo name text field handler
  late TextEditingController convoNameController;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    convoNameController =
        TextEditingController(text: widget.conversationData['name']);
  }

  @override
  Widget build(BuildContext context) {
    //stream convo's data
    Stream<DocumentSnapshot> convoStream = firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .snapshots();
    //menu
    return CupertinoPageScaffold(
      child: Center(
          child: Column(
        children: [
          //convo picture options
          CupertinoButton(
              child: StreamBuilder(
                stream: convoStream,
                builder: (context, snapshot) {
                  //get convo data
                  Map<String, dynamic> convoData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  //display convo picture
                  return CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 50,
                    backgroundImage: NetworkImage(convoData['convoPicture']),
                  );
                },
              ),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) => CupertinoActionSheet(
                    actions: [
                      //set convo pic to default/remove custom convo pic
                      CupertinoActionSheetAction(
                        child: const Text('remove convo photo'),
                        onPressed: () {
                          // Update conversation picture in Firestore
                          FirebaseFirestore.instance
                              .collection('conversations')
                              .doc(widget.conversationId)
                              .update({
                            'convoPicture':
                                "https://raw.githubusercontent.com/jumbyjumbo/images/main/pp.png",
                          });
                          Navigator.pop(context); // close the action sheet
                        },
                      ),
                      //set convo pic to custom image/replace current convo pic
                      CupertinoActionSheetAction(
                        child: const Text('change convo photo'),
                        onPressed: () {
                          Navigator.pop(context); // close the action sheet
                          //picture selection TODO
                          ImageSelect(
                                  conversationId: widget.conversationId,
                                  pathToStore: "convoProfilePics")
                              .selectImage();
                        },
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      child: const Text("cancel"),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              }),

          //convo name options
          CupertinoButton(
              child: StreamBuilder(
                stream: convoStream,
                builder: (context, snapshot) {
                  //get convo data
                  Map<String, dynamic> convoData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  //display convo name
                  return Text(
                    "${convoData['name']}",
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  );
                },
              ),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) => CupertinoActionSheet(
                    actions: [
                      CupertinoActionSheetAction(
                        child: const Text('change convo name'),
                        onPressed: () {
                          Navigator.pop(context); // close the action sheet
                          // Show bottom sheet
                          showCupertinoModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: <Widget>[
                                    // Done and cancel buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CupertinoButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.pop(
                                                context); // close the bottom sheet
                                          },
                                        ),
                                        CupertinoButton(
                                          child: const Text('Done'),
                                          onPressed: () {
                                            // Update conversation name in Firestore
                                            FirebaseFirestore.instance
                                                .collection('conversations')
                                                .doc(widget.conversationId)
                                                .update({
                                              'name': convoNameController.text,
                                            });
                                            Navigator.pop(
                                                context); // close the bottom sheet
                                          },
                                        ),
                                      ],
                                    ),
                                    // Text field to change convo name
                                    CupertinoTextFormFieldRow(
                                      decoration: BoxDecoration(
                                        color: CupertinoColors
                                            .extraLightBackgroundGray,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      controller: convoNameController,
                                      placeholder: 'Conversation Name',
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      child: const Text("cancel"),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              })

          //members horizontal list
        ],
      )),
    );
  }

  @override
  void dispose() {
    convoNameController.dispose();
    super.dispose();
  }
}

//image selection button to send images as messages
class ImageSelect {
  ImageSelect({required this.conversationId, required this.pathToStore});

  final String conversationId;
  final String pathToStore;

  Future<String> uploadImageToFirebase(XFile imageFile) async {
    if (kIsWeb) {
      return await uploadImageToFirebaseWeb(
          conversationId, imageFile, pathToStore);
    } else {
      FirebaseStorage storage = FirebaseStorage.instance;

      // Convert the XFile to a File
      File file = File(imageFile.path);

      // Extract the extension from the imageFile
      String fileExtension = path.extension(imageFile.path);
      String fullPath =
          'conversation/$conversationId/$pathToStore/${path.basename(imageFile.path)}$fileExtension';

      //store the image in firebase storage
      try {
        await storage.ref(fullPath).putFile(file);

        // Return the download URL
        String downloadURL = await storage.ref(fullPath).getDownloadURL();
        return downloadURL;
      } on FirebaseException catch (e) {
        print(e);
        return "";
      }
    }
  }

  updateConvoProfilePic(String imageUrl, String conversationId) {
    // Update conversation picture in Firestore
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .update({
      'convoPicture': imageUrl,
    });
  }

  Future<void> selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String imageUrl =
          await uploadImageToFirebase(image); // Upload the image to Firebase
      if (imageUrl.isNotEmpty) {
        await updateConvoProfilePic(imageUrl, conversationId);
      }
    }
  }
}
