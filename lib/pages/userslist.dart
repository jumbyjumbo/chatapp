import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersList extends StatelessWidget {
  final String currentUserUid;

  const UsersList({
    Key? key,
    required this.currentUserUid,
  }) : super(key: key);

  // get the list of friends of the current user
  Stream<List<String>> getFriends(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
            (snapshot) => List<String>.from(snapshot.data()?['friends'] ?? []));
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return StreamBuilder<List<String>>(
      stream: getFriends(currentUserUid),
      builder:
          (BuildContext context, AsyncSnapshot<List<String>> friendSnapshot) {
        if (friendSnapshot.connectionState == ConnectionState.waiting ||
            !friendSnapshot.hasData) {
          return Container(color: Colors.transparent);
        }

        List<String> friends = friendSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('users').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return Container(color: Colors.transparent);
            }

            //get the list of users excluding the current user and his friends
            List<QueryDocumentSnapshot> users = snapshot.data!.docs
                .where((doc) =>
                    doc.id != currentUserUid && !friends.contains(doc.id))
                .toList();

            return Column(
              children: [
                //title
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('add friends', style: TextStyle(fontSize: 25)),
                ),

                //search bar TODO

                //users list
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(width: 0.5, color: Colors.grey)),
                    ),
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        // get the user data
                        Map<String, dynamic> user =
                            users[index].data() as Map<String, dynamic>;

                        // get the user's data
                        String userName = user['name'];
                        String userPic = user['profilepicture'];
                        String userUid = users[index].id;

                        return GestureDetector(
                          onTap: () async {
                            // Add each user to the other's friends list
                            await db
                                .collection('users')
                                .doc(currentUserUid)
                                .update({
                              'friends': FieldValue.arrayUnion([userUid])
                            });
                            await db.collection('users').doc(userUid).update({
                              'friends': FieldValue.arrayUnion([currentUserUid])
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      width: 0.5, color: Colors.grey)),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(userPic),
                                radius: 25,
                              ),
                              const SizedBox(width: 20),
                              Text(userName,
                                  style: const TextStyle(
                                      // fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
