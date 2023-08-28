import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ConvoListState {}

class ConvoListInitial extends ConvoListState {}

class ConvoListLoading extends ConvoListState {}

class ConvoListLoaded extends ConvoListState {
  final List<QueryDocumentSnapshot> conversations;

  ConvoListLoaded(this.conversations);
}

class ConvoListError extends ConvoListState {
  final String message;
  ConvoListError(this.message);
}

class ConvoUpdated extends ConvoListState {
  final String convoId;
  final Map<String, dynamic> updatedData;
  ConvoUpdated(this.convoId, this.updatedData);
}
