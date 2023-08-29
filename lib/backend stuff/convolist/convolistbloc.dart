import 'dart:async';
import 'convolistevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'convoliststate.dart';

class ConvoListBloc extends Bloc<ConvoListEvent, ConvoListState> {
  final User user;
  late StreamSubscription<QuerySnapshot> _subscription;

  ConvoListBloc(this.user) : super(ConvoListInitial()) {
    on<LoadConvoList>(_loadConvoList);
    on<ConvoListNewData>(_newConvoData);
  }

  Future<void> _loadConvoList(
      LoadConvoList event, Emitter<ConvoListState> emit) async {
    emit(ConvoListLoading());

    _subscription = FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: user.uid)
        .orderBy('lastmessagetimestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      emit(ConvoListLoaded(snapshot.docs));
    });
  }

  Future<void> _newConvoData(
      ConvoListNewData event, Emitter<ConvoListState> emit) async {
    emit(ConvoListLoaded(event.conversations));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
