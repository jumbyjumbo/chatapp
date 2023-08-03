import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  //list of friends to be added to the new convo
  List<String> selectedFriends = [];

  // Create a new conversation with the selected users + current user
  Future<void> createConversation(List<String> memberIds) async {
    final DateTime now = DateTime.now(); // creates a new timestamp
    String defaultName = "Chat";
    String defaultPic =
        "https://raw.githubusercontent.com/jumbyjumbo/images/main/pp.png";

    // Include the current user in the conversation
    if (!memberIds.contains(widget.userId)) {
      memberIds.add(widget.userId);
    }

    //create the conversation
    DocumentReference conversationDoc =
        await FirebaseFirestore.instance.collection('conversations').add({
      'name': defaultName,
      'members': memberIds,
      'convoPicture': defaultPic,
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
    Navigator.pop(context);
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
        List<String> friends = List<String>.from(snapshot.data!.get('friends'));

        return Column(
          children: [
            //title
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('new convo', style: TextStyle(fontSize: 25)),
            ),

            //search bar TODO

            //list of friends
            Expanded(
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(); //
                },
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
                        profilePicture: snapshot.data!.get('profilepicture'),
                      );

                      return FriendInstanceWidget(
                        friend: friend,
                        initiallySelected: selectedFriends.contains(friend.id),
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
            //create convo button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: CupertinoButton(
                color: Colors.blue,
                onPressed: selectedFriends.isEmpty
                    ? null
                    : () {
                        createConversation(
                            selectedFriends); //create the convo with the selected friends
                      },
                child: const Center(child: Text('create convo')),
              ),
            ),
          ],
        );
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
        color: isSelected ? Colors.grey.withOpacity(0.2) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(widget.friend.profilePicture),
              radius: 25,
            ),
            const SizedBox(width: 20),
            Text(widget.friend.name),
          ]),
        ),
      ),
    );
  }
}
