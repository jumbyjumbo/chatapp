import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'convoinstanceevent.dart';
import 'convoinstancestate.dart';

class ConvoInstanceBloc extends Bloc<ConvoInstanceEvent, ConvoInstanceState> {
  late StreamSubscription<DocumentSnapshot> _subscription;

  ConvoInstanceBloc(String convoId) : super(ConvoInstanceInitial()) {
    _subscription = const Stream<DocumentSnapshot>.empty().listen((_) {});
    on<LoadConvoInstance>(_loadConvoInstance);
    on<ConvoInstanceNewData>(_newConvoData);
  }

  Future<void> _loadConvoInstance(
      LoadConvoInstance event, Emitter<ConvoInstanceState> emit) async {
    emit(ConvoInstanceLoading());

    // Await to make sure the subscription is fully cancelled
    await _subscription.cancel();

    // Create a new subscription
    _subscription = FirebaseFirestore.instance
        .collection('conversations')
        .doc(event.convoId)
        .snapshots()
        .listen(
      (snapshot) {
        add(ConvoInstanceNewData(snapshot.data() as Map<String, dynamic>));
      },
    );
  }

  Future<void> _newConvoData(
      ConvoInstanceNewData event, Emitter<ConvoInstanceState> emit) async {
    emit(ConvoInstanceLoaded(
        event.convoData['convoPicUrl'], event.convoData['convoName']));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
