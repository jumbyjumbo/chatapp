import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnlineStatusDot extends StatelessWidget {
  const OnlineStatusDot({super.key, required this.userData, this.size = 14});

  //get user data
  final Map<String, dynamic> userData;
  //size
  final double size;

  //get online status dot color from Isonline and lastseen
  Color onlineStatusDotColor() {
    // Check if the user is online
    bool isOnline = userData['isOnline'] ?? false;
    if (isOnline) return Colors.green;

    // Check the last seen time
    Timestamp? lastSeen = userData['lastSeen'] as Timestamp?;
    if (lastSeen == null) return Colors.grey;

    final difference = DateTime.now().difference(lastSeen.toDate());
    return difference.inMinutes < 10 ? Colors.orange : Colors.grey;
  }

  //build the widget
  @override
  Widget build(BuildContext context) {
    //border around status dot
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
