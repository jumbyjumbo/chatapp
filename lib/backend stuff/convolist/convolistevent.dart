import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ConvoListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadConvoList extends ConvoListEvent {}

class ConvoListNewData extends ConvoListEvent {
  final List<QueryDocumentSnapshot> conversations;

  ConvoListNewData(this.conversations);

  @override
  List<Object?> get props => [conversations];
}
