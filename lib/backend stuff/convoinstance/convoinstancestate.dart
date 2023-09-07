import 'package:equatable/equatable.dart';

abstract class ConvoInstanceState extends Equatable {
  const ConvoInstanceState();

  @override
  List<Object> get props => [];
}

class ConvoInstanceInitial extends ConvoInstanceState {}

class ConvoInstanceLoading extends ConvoInstanceState {}

class ConvoInstanceLoaded extends ConvoInstanceState {
  final String convoPicUrl;
  final String convoName;
  // Add other relevant data

  const ConvoInstanceLoaded(this.convoPicUrl, this.convoName);

  @override
  List<Object> get props => [convoPicUrl, convoName];
}
