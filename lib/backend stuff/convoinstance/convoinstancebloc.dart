import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'convoinstanceevent.dart';
import 'convoinstancestate.dart';
import '../convolist/convolistbloc.dart';
import '../convolist/convoliststate.dart';

class ConvoInstanceBloc extends Bloc<ConvoInstanceEvent, ConvoInstanceState> {
  final ConvoListBloc convoListBloc;
  late StreamSubscription<ConvoListState> _convoListSubscription;

  final String convoId; // Add this line to store the conversation ID

  ConvoInstanceBloc(this.convoListBloc, this.convoId)
      : super(ConvoInstanceInitial()) {
    _convoListSubscription = convoListBloc.stream.listen((state) {
      if (state is ConvoListLoaded) {
        final convoData =
            state.conversations.firstWhere((convo) => convo.id == convoId);

        add(ConvoInstanceNewData(convoData.data() as Map<String, dynamic>));
      }
    });

    on<LoadConvoInstance>(_loadConvoInstance);
    on<ConvoInstanceNewData>(_newConvoData);
  }

  Future<void> _loadConvoInstance(
      LoadConvoInstance event, Emitter<ConvoInstanceState> emit) async {
    // Loading logic can go here, or it can be managed by the ConvoListBloc
  }

  Future<void> _newConvoData(
      ConvoInstanceNewData event, Emitter<ConvoInstanceState> emit) async {
    emit(ConvoInstanceLoaded(
        event.convoData['convoPicUrl'], event.convoData['convoName']));
  }

  @override
  Future<void> close() {
    _convoListSubscription.cancel();
    return super.close();
  }
}
