import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConvoStatusDot extends StatelessWidget {
  const ConvoStatusDot({super.key, required this.membersData, this.size = 14});

  // List of user data from the members list
  final List<Map<String, dynamic>> membersData;
  final double size;

  Color onlineStatusDotColor() {
    // If at least one member is online, return green
    if (membersData.any((userData) => userData['isOnline'] ?? false)) {
      return Colors.green;
    }

    // If at least one member has been active in the past 10 minutes, return orange
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    if (membersData.any((userData) {
      Timestamp? lastSeen = userData['lastSeen'] as Timestamp?;
      if (lastSeen == null) return false;
      return lastSeen.toDate().isAfter(tenMinutesAgo);
    })) {
      return Colors.orange;
    }

    // Otherwise, return grey
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    double statusDotBorder = size * 1.45; // Outer container is slightly bigger

    return Container(
      width: statusDotBorder,
      height: statusDotBorder,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).primaryColor == CupertinoColors.black
            ? CupertinoColors.white
            : CupertinoColors.black,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onlineStatusDotColor(),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
