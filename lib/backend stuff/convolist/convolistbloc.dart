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
        final convos = snapshot.docs.map((doc) => doc).toList();
        add(LoadConvoList(convos));
      },
    );

    on<LoadConvoList>((event, emit) async {
      emit(ConvoListLoading());

      emit(ConvoListLoaded(event.convos));
    });
  }
}
