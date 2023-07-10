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
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
          child: CupertinoListSection(
        header: const Text('Convo Settings'),
        children: [
          //textfield to change convo name
          CupertinoTextFormFieldRow(
            initialValue: widget.conversationData[
                'name'], // Use the initial name from conversationData
            placeholder: 'Conversation Name',
            onChanged: (value) {
              // Update conversation name in Firestore
              FirebaseFirestore.instance
                  .collection('globalConvos')
                  .doc(widget.conversationId)
                  .update({
                'name': value,
              });
            },
          ),
        ],
      )),
    );
  }
}
