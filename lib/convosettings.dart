import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

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
          child: CupertinoListSection(
        header: const Text('Convo Settings'),
        children: [
          //textfield to change convo name
          CupertinoTextFormFieldRow(
            controller: _nameController,
            placeholder: 'Conversation Name',
          ),
          CupertinoButton(
            child: const Text('Update Conversation Name'),
            onPressed: () {
              // Update conversation name in Firestore
              FirebaseFirestore.instance
                  .collection('globalConvos')
                  .doc(widget.conversationId)
                  .update({
                'name': _nameController.text,
              });
            },
          ),
          //change convo picture
          CupertinoButton(
              child: const Text('Change Conversation Picture'),
              onPressed: () {})
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
