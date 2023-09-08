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

class ConvoNameChanged extends ConvoInstanceEvent {
  final String newName;

  const ConvoNameChanged(this.newName);

  @override
  List<Object> get props => [newName];
}

class ConvoPicChanged extends ConvoInstanceEvent {
  final String newPicUrl;

  const ConvoPicChanged(this.newPicUrl);

  @override
  List<Object> get props => [newPicUrl];
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
