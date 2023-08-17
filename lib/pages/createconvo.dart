import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pleasepleasepleaseplease/ui%20stuff/uifx.dart';
import 'messagingpage.dart';

//friend class for ease of use
class Friend {
  final String id;
  final String name;
  final String profilePicture;

  Friend({required this.id, required this.name, required this.profilePicture});
}

class FriendsList extends StatefulWidget {
  final String userId;

  const FriendsList({Key? key, required this.userId}) : super(key: key);

  @override
  FriendsListState createState() => FriendsListState();
}

class FriendsListState extends State<FriendsList> {
  final GlobalKey formKey = GlobalKey();
  //list of friends to be added to the new convo
  List<String> selectedFriends = [];

  bool isSendingMsg = false;

  //controller for the initial message text field
  final TextEditingController initialMsgController = TextEditingController();

  // Create a new conversation with the selected users + current user
  Future<String> createConversation(List<String> memberIds) async {
    final DateTime now = DateTime.now(); // creates a new timestamp

    //set default convo name
    String defaultConvoName = "new convo";

    //set default convo picture
    String defaultConvoPic =
        "https://raw.githubusercontent.com/jumbyjumbo/images/main/groupchat.jpg";

    // Include the current user in the conversation
    if (!memberIds.contains(widget.userId)) {
      memberIds.add(widget.userId);
    }

    //create the conversation
    DocumentReference conversationDoc =
        await FirebaseFirestore.instance.collection('conversations').add({
      'name': defaultConvoName,
      'members': memberIds,
      'convoPicture': defaultConvoPic,
      'lastmessagetimestamp': now,
    });

    //for each member, add the conversation to their list of convos
    for (String id in memberIds) {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(id);
      await userDoc.update({
        'convos': FieldValue.arrayUnion([conversationDoc.id]),
      });
    }
    // Pop the create convo page
    // ignore: use_build_context_synchronously
    Navigator.pop(context);

    // Return the conversation ID
    return conversationDoc.id;
  }

  Future<void> sendInitialMessage(String conversationId, String content) async {
    final DateTime now = DateTime.now();
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;

    FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'type': 'text',
      'sender': widget.userId,
      'senderName': userData['name'],
      'senderProfilePicture': userData['profilepicture'],
      'content': content,
      'timestamp': now,
    }).then((value) {
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastmessage': value.id,
        'lastmessagetimestamp': now,
      });
    });
  }

  void sendMessage() async {
    if (isSendingMsg) return; // Prevent sending if already sending

    setState(() {
      isSendingMsg = true; // Mark as sending
    });

    String newConvoId = await createConversation(selectedFriends);
    await sendInitialMessage(newConvoId, initialMsgController.text);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => Messagingpage(
          conversationId: newConvoId,
        ),
      ),
    );

    setState(() {
      isSendingMsg = false; // Mark as done sending
    });
  }

  @override
  void initState() {
    super.initState();
    initialMsgController.addListener(() {
      setState(() {}); // Forces rebuild when the text changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        List<String> friends =
            List<String>.from(snapshot.data?.get('friends') ?? []);
        return Stack(children: [
          //list of friends
          Column(
            children: [
              //title
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('new convo', style: TextStyle(fontSize: 25)),
              ),

              //search bar TODO

              //list of friends
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(width: 0.5, color: Colors.grey)),
                  ),
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friends[index])
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final friend = Friend(
                            id: friends[index],
                            name: snapshot.data!.get('name'),
                            profilePicture:
                                snapshot.data!.get('profilepicture'),
                          );

                          return FriendInstanceWidget(
                            friend: friend,
                            initiallySelected:
                                selectedFriends.contains(friend.id),
                            onSelectedChanged: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedFriends.add(friend.id);
                                } else {
                                  selectedFriends.remove(friend.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          //create convo button/text field
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: BlurEffectView(
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  //if press shift+enter, send message
                  onKey: (RawKeyEvent event) {
                    if (event.isShiftPressed &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        initialMsgController.text.isNotEmpty) {
                      //trim the skip line added by the enter key
                      initialMsgController.text =
                          initialMsgController.text.trim();
                      sendMessage();
                    }
                  },
                  child: CupertinoTextField(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      border: null,
                    ),
                    controller: initialMsgController,
                    placeholder: "message",
                    placeholderStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.placeholderText),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLength: 1000,
                    maxLines: 10,
                    minLines: 1,
                    suffix: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CupertinoButton(
                        disabledColor: Colors.grey,
                        padding: EdgeInsets.zero,
                        onPressed: initialMsgController.text.isEmpty
                            ? null
                            : () {
                                sendMessage();
                              },
                        child: const Text('Send',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class FriendInstanceWidget extends StatefulWidget {
  final Friend friend;
  final bool initiallySelected;
  final ValueChanged<bool> onSelectedChanged;

  const FriendInstanceWidget({
    Key? key,
    required this.friend,
    this.initiallySelected = false,
    required this.onSelectedChanged,
  }) : super(key: key);

  @override
  FriendInstanceWidgetState createState() => FriendInstanceWidgetState();
}

class FriendInstanceWidgetState extends State<FriendInstanceWidget> {
  late bool isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = widget.initiallySelected;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = !isSelected;
          widget.onSelectedChanged(isSelected);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.withOpacity(0.2) : Colors.transparent,
          //border on the bottom 0.5 grey
          border:
              const Border(bottom: BorderSide(width: 0.5, color: Colors.grey)),
        ),
        //padding for the friend card
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            //friend pp
            CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(widget.friend.profilePicture),
              radius: 25,
            ),
            const SizedBox(width: 20),
            //friend name
            Text(widget.friend.name),
          ]),
        ),
      ),
    );
  }
}
