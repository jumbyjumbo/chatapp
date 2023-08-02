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
  final FirebaseFirestore db = FirebaseFirestore.instance;

  ValueNotifier<List<String>> selectedUsers = ValueNotifier<List<String>>([]);

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
    // Reset selected users
    selectedUsers.value = [];

    // Pop the create convo page
    //Navigator.pop(context);
  }

  void updateSelectedUsers(String userId, bool isSelected) {
    if (isSelected) {
      selectedUsers.value.add(userId);
    } else {
      selectedUsers.value.removeWhere((user) => user == userId);
    }
    selectedUsers.value =
        List.from(selectedUsers.value); // Set a new list instance
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('users').doc(widget.userId).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return Container(color: Colors.transparent);
        }

        List<String> friends = List<String>.from(snapshot.data!.get('friends'));

        return Column(
          children: [
            //title
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('new convo', style: TextStyle(fontSize: 25)),
            ),

            //search bar TODO

            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: db.collection('users').doc(friends[index]).get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }

                      final friend = Friend(
                        id: friends[index],
                        name: snapshot.data!.get('name'),
                        profilePicture: snapshot.data!.get('profilepicture'),
                      );

                      return FriendWidget(
                        friend: friend,
                        initiallySelected:
                            selectedUsers.value.contains(friends[index]),
                        onSelectedChanged: (isSelected) {
                          updateSelectedUsers(friends[index], isSelected);
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
              child: ValueListenableBuilder<List<String>>(
                valueListenable: selectedUsers,
                builder: (context, selectedUsersValue, child) {
                  return CupertinoButton(
                    color: Colors.blue,
                    onPressed: selectedUsersValue.isEmpty
                        ? null
                        : () {
                            createConversation(selectedUsersValue);
                          },
                    child: const Center(child: Text('create convo')),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class FriendWidget extends StatefulWidget {
  final Friend friend;
  final bool initiallySelected;
  final ValueChanged<bool> onSelectedChanged;

  const FriendWidget({
    Key? key,
    required this.friend,
    this.initiallySelected = false,
    required this.onSelectedChanged,
  }) : super(key: key);

  @override
  FriendWidgetState createState() => FriendWidgetState();
}

class FriendWidgetState extends State<FriendWidget> {
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
