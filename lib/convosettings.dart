import 'package:flutter/cupertino.dart';

class ConversationSettings extends StatefulWidget {
  const ConversationSettings({Key? key}) : super(key: key);

  @override
  ConversationSettingsState createState() => ConversationSettingsState();
}

class ConversationSettingsState extends State<ConversationSettings> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
          child: CupertinoListSection(
        children: [
          CupertinoListTile(
            title: Text('Conversation Settings'),
          ),
        ],
      )),
    );
  }
}
