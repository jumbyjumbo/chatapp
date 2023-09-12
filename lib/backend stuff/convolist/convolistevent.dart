import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ConvoListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadConvoList extends ConvoListEvent {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> convos;

  LoadConvoList(this.convos);

  @override
  List<Object> get props => [convos];
}
