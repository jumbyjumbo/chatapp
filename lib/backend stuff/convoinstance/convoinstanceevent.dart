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

class ConvoInstanceNewData extends ConvoInstanceEvent {
  final Map<String, dynamic> convoData;

  const ConvoInstanceNewData(this.convoData);
}
