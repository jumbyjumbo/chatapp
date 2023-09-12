import 'dart:async';
import 'convolistevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'convoliststate.dart';

class ConvoListBloc extends Bloc<ConvoListEvent, ConvoListState> {
  final User user;
  late StreamSubscription<QuerySnapshot> convoListStream;

  ConvoListBloc(this.user) : super(ConvoListInitial()) {
    //get list of convos
    convoListStream = FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: user.uid)
        .orderBy('lastmessagetimestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        add(LoadConvoList(snapshot.docs));
      },
    );

    on<LoadConvoList>(loadConvoList);
  }

  Future<void> loadConvoList(
      LoadConvoList event, Emitter<ConvoListState> emit) async {
    emit(ConvoListLoaded(event.convos));
  }
}
