import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ConvoListEvent {}

class LoadConvoList extends ConvoListEvent {}

// Internal event to update the list of conversations
class ConvoListNewData extends ConvoListEvent {
  final List<QueryDocumentSnapshot> conversations;
  ConvoListNewData(this.conversations);
}
