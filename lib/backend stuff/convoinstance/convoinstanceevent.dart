import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

abstract class ConvoInstanceEvent extends Equatable {
  const ConvoInstanceEvent();

  @override
  List<Object> get props => [];
}

class LoadConvoInstance extends ConvoInstanceEvent {
  final Map<String, dynamic> convoData;

  LoadConvoInstance(this.convoData);

  @override
  List<Object> get props => [convoData];
}
