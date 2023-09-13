import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'convoinstanceevent.dart';
import 'convoinstancestate.dart';

class ConvoInstanceBloc extends Bloc<ConvoInstanceEvent, ConvoInstanceState> {
  final String convoId;
  final String userId;
  late StreamSubscription<DocumentSnapshot> convoDataStream;
  String defaultConvoPic =
      "https://raw.githubusercontent.com/jumbyjumbo/images/main/groupchat.jpg";

  ConvoInstanceBloc({required this.convoId, required this.userId})
      : super(ConvoInstanceInitial()) {
    convoDataStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(convoId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>;
      // Emit the LoadConvoInstance event with the updated data
      add(LoadConvoInstance(data));
    });

    on<LoadConvoInstance>(loadConvoInstance);
  }

  Future<void> loadConvoInstance(
      LoadConvoInstance event, Emitter<ConvoInstanceState> emit) async {
    emit(ConvoInstanceLoading());

    // Get the convo data
    final convoData = event.convoData;

    // Fetch the conversation name
    String uIConvoName = await getConvoName(convoData);

    // Fetch the conversation picture
    String uIConvoPic = await getConvoPic(convoData);

    // Fetch the formatted last message
    String uILastMessage =
        await getFormattedLastMessage(convoData['lastmessage']);

    // Determine if the last message is read
    bool isLastMessageRead = convoData['hasread'].contains(userId);

    // Emit the new state
    emit(ConvoInstanceLoaded(
        uIConvoName, uIConvoPic, uILastMessage, isLastMessageRead));
  }

  Future<String> getConvoName(Map<String, dynamic> convoData) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String newName = convoData['name'];

    // If there are 2 members, get the other user's name
    if (convoData['members'].length == 2) {
      String otherUserId = convoData['members'][0] == userId
          ? convoData['members'][1]
          : convoData['members'][0];
      DocumentSnapshot otherUserDoc =
          await firestore.collection('users').doc(otherUserId).get();
      newName = otherUserDoc['name'];
    }

    return newName;
  }

  Future<String> getConvoPic(Map<String, dynamic> convoData) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String newPicUrl = convoData["convoPicture"] ?? defaultConvoPic;

    QuerySnapshot lastImageSentSnapshot = await firestore
        .collection('conversations')
        .doc(convoId)
        .collection("messages")
        .where('type', isEqualTo: 'image')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    // Display the last image sent
    if (lastImageSentSnapshot.docs.isNotEmpty) {
      newPicUrl = lastImageSentSnapshot.docs[0]['content'] ?? defaultConvoPic;
      // Or display the other user's profile picture
    } else if (convoData['members'].length == 2) {
      String otherUserId = convoData['members'][0] == userId
          ? convoData['members'][1]
          : convoData['members'][0];
      DocumentSnapshot otherUserDoc =
          await firestore.collection('users').doc(otherUserId).get();
      newPicUrl = otherUserDoc['profilepicture'] ?? defaultConvoPic;
    }

    return newPicUrl;
  }

  Future<String> getFormattedLastMessage(String newLastMessage) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the last message data
    DocumentSnapshot lastMessageSnapshot = await firestore
        .collection('conversations')
        .doc(convoId)
        .collection("messages")
        .doc(newLastMessage)
        .get();

    Map<String, dynamic> lastMessageData =
        lastMessageSnapshot.data() as Map<String, dynamic>;

    // Get the last message sender's name
    DocumentSnapshot senderDoc = await firestore
        .collection('users')
        .doc(lastMessageData['sender'])
        .get();
    String senderName = senderDoc['name'];

    // Get how long ago the last message was sent
    int secondsAgo = DateTime.now()
        .difference((lastMessageData['timestamp'] as Timestamp).toDate())
        .inSeconds;

    // Determine message content
    String content;
    if (lastMessageData['type'] == 'image') {
      content = 'sent a picture';
    } else {
      content = lastMessageData['content'];
      if (content.length > 20) {
        content = '${content.substring(0, 20)}...';
      }
    }

    // Add sender name if needed
    String senderNamePrefix = "";
    if (/*convoData['members'].length > 2 &&*/ lastMessageData['sender'] !=
        userId) {
      senderNamePrefix = "$senderName: ";
    }

    // Calculate time ago
    String timeAgo = secondsAgo < 10
        ? "just now"
        : GetTimeAgo.parse(
            (lastMessageData['timestamp'] as Timestamp).toDate());

    // Create the formatted last message
    String formattedLastMessage = "$senderNamePrefix$content • $timeAgo";

    return formattedLastMessage;
  }
}
