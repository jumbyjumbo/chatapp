import 'dart:async';
import 'convolistevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'convoliststate.dart';

class ConvoListBloc extends Bloc<ConvoListEvent, ConvoListState> {
  final User user;
  late StreamSubscription<QuerySnapshot> subscription;

  ConvoListBloc(this.user) : super(ConvoListInitial()) {
    subscription = const Stream<QuerySnapshot>.empty().listen((_) {});
    on<LoadConvoList>(loadConvoList);
    on<ConvoListNewData>(newConvoData);
  }

  Future<void> loadConvoList(
      LoadConvoList event, Emitter<ConvoListState> emit) async {
    emit(ConvoListLoading());

    // Await to make sure the subscription is fully cancelled
    await subscription.cancel();

    // Create a new subscription
    subscription = FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: user.uid)
        .orderBy('lastmessagetimestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        add(ConvoListNewData(snapshot.docs));
      },
    );
  }

  Future<void> newConvoData(
      ConvoListNewData event, Emitter<ConvoListState> emit) async {
    emit(ConvoListLoaded(event.conversations));
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}
