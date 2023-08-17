import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConvoStatusDot extends StatelessWidget {
  const ConvoStatusDot({Key? key, required this.convoData, this.size = 14})
      : super(key: key);

  // Get conversation data
  final Map<String, dynamic> convoData;
  // Dot size
  final double size;

  Future<Color> getConvoStatusColor() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    // Fetch 'isOnline' and 'lastSeen' for all members of the conversation
    final memberStatuses =
        await Future.wait(convoData['members'].map((userId) async {
      final userDoc = await usersCollection.doc(userId).get();
      final userData = userDoc.data();
      return {
        'isOnline': userData?['isOnline'] ?? false,
        'lastSeen': userData?['lastSeen']
      };
    }));

    // If at least one member is online, return green
    if (memberStatuses.any((status) => status['isOnline'])) {
      return Colors.green;
    }

    // If at least one member has been active in the past 10 minutes, return orange
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    if (memberStatuses.any((status) {
      final lastSeen = (status['lastSeen'] as Timestamp?)?.toDate();
      return lastSeen != null && lastSeen.isAfter(tenMinutesAgo);
    })) {
      return Colors.orange;
    }

    // Otherwise, return grey
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    double statusDotBorder = size * 1.45; // Outer container is slightly bigger

    return FutureBuilder<Color>(
      future: getConvoStatusColor(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Or you can show a loader here
        }
        return Container(
          width: statusDotBorder,
          height: statusDotBorder,
          decoration: BoxDecoration(
            color:
                CupertinoTheme.of(context).primaryColor == CupertinoColors.black
                    ? CupertinoColors.white
                    : CupertinoColors.black,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: snapshot.data,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
