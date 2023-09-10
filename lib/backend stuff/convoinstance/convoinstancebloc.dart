import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'convoinstanceevent.dart';
import 'convoinstancestate.dart';
import '../convolist/convolistbloc.dart';
import '../convolist/convoliststate.dart';

class ConvoInstanceBloc extends Bloc<ConvoInstanceEvent, ConvoInstanceState> {
  final ConvoListBloc convoListBloc;
  late StreamSubscription<ConvoListState> convodatastream;
  final String convoId;
  final String userId;
  String convoName = '';
  String convoPicUrl = '';
  String lastMessage = '';
  bool isLastMessageRead = true;

  String defaultConvoPic =
      "https://raw.githubusercontent.com/jumbyjumbo/images/main/groupchat.jpg";

  ConvoInstanceBloc(this.convoListBloc, this.convoId, this.userId)
      : super(ConvoInstanceInitial()) {
    convoListBloc.stream.listen((state) {
      if (state is ConvoListLoaded) {
        // Get the convo data when the convo list is loaded
        final convoData =
            state.conversations.firstWhere((convo) => convo.id == convoId);

        // Use the data to update the bloc state
        // Trigger the appropriate events based on the data received

        if (convoName != convoData['name']) {
          add(ConvoNameChanged(convoData));
        }

        if (convoPicUrl != convoData['convopic']) {
          add(ConvoPicChanged(convoData));
        }

        if (lastMessage != convoData['lastmessage']) {
          add(LastMessageSent(convoData['lastmessage']));
        }

        if (isLastMessageRead != convoData['hasread'].contains(userId)) {
          add(LastMessageReadStatusChanged(
              convoData['hasread'].contains(userId)));
        }
      }
    });

    on<ConvoNameChanged>(convoNameChanged);
    on<ConvoPicChanged>(convoPicChanged);
    on<LastMessageSent>(lastMessageSent);
    on<LastMessageReadStatusChanged>(lastMessageReadStatusChanged);
  }

  Future<void> convoNameChanged(
      ConvoNameChanged event, Emitter<ConvoInstanceState> emit) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final convoData = event.convoData;
    String newName = convoData['name'];

    //if theres 2 members, get the other user's name
    if (convoData['members'].length == 2) {
      String otherUserId = convoData['members'][0] == userId
          ? convoData['members'][1]
          : convoData['members'][0];
      DocumentSnapshot otherUserDoc =
          await firestore.collection('users').doc(otherUserId).get();
      newName = otherUserDoc['name'];
    }

    convoName = newName;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  Future<void> convoPicChanged(
      ConvoPicChanged event, Emitter<ConvoInstanceState> emit) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final convoData = event.convoData;
    String newPicUrl = convoData["convopic"] ?? defaultConvoPic;

    QuerySnapshot lastImageSentSnapshot = await firestore
        .collection('conversations')
        .doc(convoId)
        .collection("messages")
        .where('type', isEqualTo: 'image')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    //display last image sent
    if (lastImageSentSnapshot.docs.isNotEmpty) {
      newPicUrl = lastImageSentSnapshot.docs[0]['content'] ?? defaultConvoPic;
      //or display other user's profile picture
    } else if (convoData['members'].length == 2) {
      String otherUserId = convoData['members'][0] == userId
          ? convoData['members'][1]
          : convoData['members'][0];
      DocumentSnapshot otherUserDoc =
          await firestore.collection('users').doc(otherUserId).get();
      newPicUrl = otherUserDoc['profilepicture'] ?? defaultConvoPic;
    }

    convoPicUrl = newPicUrl;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  Future<void> lastMessageSent(
      LastMessageSent event, Emitter<ConvoInstanceState> emit) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the last message data
    DocumentSnapshot lastMessageSnapshot = await firestore
        .collection('conversations')
        .doc(convoId)
        .collection("messages")
        .doc(event.newLastMessage)
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

    //add sender name if needed
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

    // Update state
    lastMessage = formattedLastMessage;
    isLastMessageRead = false;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  Future<void> lastMessageReadStatusChanged(LastMessageReadStatusChanged event,
      Emitter<ConvoInstanceState> emit) async {
    isLastMessageRead = event.isRead;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  @override
  Future<void> close() {
    convodatastream.cancel();
    return super.close();
  }
}
