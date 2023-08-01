import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ConversationSettings extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversationData;

  const ConversationSettings(
      {Key? key, required this.conversationId, required this.conversationData})
      : super(key: key);

  @override
  ConversationSettingsState createState() => ConversationSettingsState();
}

class ConversationSettingsState extends State<ConversationSettings> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.conversationData['name']);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
          child: Column(
        children: [
          //convo picture options
          CupertinoButton(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    NetworkImage(widget.conversationData['convoPicture']),
              ),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) => CupertinoActionSheet(
                    actions: [
                      CupertinoActionSheetAction(
                        child: const Text('remove convo photo'),
                        onPressed: () {},
                      ),
                      CupertinoActionSheetAction(
                        child: const Text('change convo photo'),
                        onPressed: () {},
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
              child: Text("${widget.conversationData['name']}"),
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
                                              'name': _nameController.text,
                                            });
                                            Navigator.pop(
                                                context); // close the bottom sheet
                                          },
                                        ),
                                      ],
                                    ),
                                    CupertinoTextFormFieldRow(
                                      controller: _nameController,
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
        ],
      )),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
