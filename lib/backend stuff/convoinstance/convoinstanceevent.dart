import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

abstract class ConvoInstanceEvent extends Equatable {
  const ConvoInstanceEvent();

  @override
  List<Object> get props => [];
}

class LoadConvoInstance extends ConvoInstanceEvent {
  final String convoId;

  const LoadConvoInstance(this.convoId);

  @override
  List<Object> get props => [convoId];
}

//when convo name is changed
class ConvoNameChanged extends ConvoInstanceEvent {
  final QueryDocumentSnapshot<Object?> convoData;

  const ConvoNameChanged(this.convoData);
}

//when convo pic is changed
class ConvoPicChanged extends ConvoInstanceEvent {
  final QueryDocumentSnapshot<Object?> convoData;

  const ConvoPicChanged(this.convoData);
}

class LastMessageSent extends ConvoInstanceEvent {
  final String newLastMessage;

  const LastMessageSent(this.newLastMessage);

  @override
  List<Object> get props => [newLastMessage];
}

class LastMessageReadStatusChanged extends ConvoInstanceEvent {
  final bool isRead;

  const LastMessageReadStatusChanged(this.isRead);

  @override
  List<Object> get props => [isRead];
}
