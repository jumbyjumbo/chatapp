import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendsList extends StatefulWidget {
  final String userId;

  const FriendsList({Key? key, required this.userId}) : super(key: key);

  @override
  FriendsListState createState() => FriendsListState();
}

class FriendsListState extends State<FriendsList> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // For keeping track of selected friends
  final selectedUsers = <String>[];

  // Create a new conversation with the selected users + current user
  Future<void> createConversation(List<String> memberIds) async {
    final DateTime now = DateTime.now(); // creates a new timestamp
    String defaultName = "Group Chat";
    String defaultPic =
        "https://raw.githubusercontent.com/jumbyjumbo/images/main/pp.png";

    // Include the current user in the conversation
    memberIds.add(widget.userId);
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
    // Clear selectedUsers list after successfully creating the conversation
    setState(() {
      selectedUsers.clear();
    });
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

            //friend list
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream:
                        db.collection('users').doc(friends[index]).snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData) {
                        return Container(color: Colors.transparent);
                      }

                      String friendName = snapshot.data!.get('name');
                      String friendPic = snapshot.data!.get('profilepicture');

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedUsers.contains(friends[index])) {
                              selectedUsers.remove(friends[index]);
                            } else {
                              selectedUsers.add(friends[index]);
                            }
                          });
                        },
                        child: Container(
                          color: selectedUsers.contains(friends[index])
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(friendPic),
                                radius: 25,
                              ),
                              const SizedBox(width: 20),
                              Text(friendName),
                            ]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                createConversation(selectedUsers);
              },
              child: const Text('Create Conversation'),
            ),
          ],
        );
      },
    );
  }
}
