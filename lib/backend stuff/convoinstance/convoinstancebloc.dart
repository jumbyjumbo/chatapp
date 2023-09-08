import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'convoinstanceevent.dart';
import 'convoinstancestate.dart';
import '../convolist/convolistbloc.dart';
import '../convolist/convoliststate.dart';

class ConvoInstanceBloc extends Bloc<ConvoInstanceEvent, ConvoInstanceState> {
  final ConvoListBloc convoListBloc;
  late StreamSubscription<ConvoListState> _convoListSubscription;
  final String convoId;
  final String userId;

  String convoName = '';
  String convoPicUrl = '';
  String lastMessage = '';
  bool isLastMessageRead = true;

  ConvoInstanceBloc(this.convoListBloc, this.convoId, this.userId)
      : super(ConvoInstanceInitial()) {
    _convoListSubscription = convoListBloc.stream.listen((state) {
      if (state is ConvoListLoaded) {
        // Get the convo data when the convo list is loaded
        final convoData =
            state.conversations.firstWhere((convo) => convo.id == convoId);

        // Use the data to update the bloc state
        // Trigger the appropriate events based on the data received

        if (convoName != convoData['name']) {
          add(ConvoNameChanged(convoData['name']));
        }

        if (convoPicUrl != convoData['convopic']) {
          add(ConvoPicChanged(convoData['convopic']));
        }

        if (lastMessage != convoData['lastmessage']) {
          add(LastMessageSent(convoData['lastmessage']));
        }

        if (isLastMessageRead != convoData['hasread'].contains(userId)) {
          add(LastMessageReadStatusChanged(
              convoData['hasread'].contains(userId)));
        }
      }
    });

    on<LoadConvoInstance>(_loadConvoInstance);
    on<ConvoNameChanged>(_convoNameChanged);
    on<ConvoPicChanged>(_convoPicChanged);
    on<LastMessageSent>(_lastMessageSent);
    on<LastMessageReadStatusChanged>(_lastMessageReadStatusChanged);
  }

  Future<void> _loadConvoInstance(
      LoadConvoInstance event, Emitter<ConvoInstanceState> emit) async {
    emit(ConvoInstanceLoading());
    // Do your initial loading logic here
  }

  Future<void> _convoNameChanged(
      ConvoNameChanged event, Emitter<ConvoInstanceState> emit) async {
    convoName = event.newName;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  Future<void> _convoPicChanged(
      ConvoPicChanged event, Emitter<ConvoInstanceState> emit) async {
    convoPicUrl = event.newPicUrl;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  Future<void> _lastMessageSent(
      LastMessageSent event, Emitter<ConvoInstanceState> emit) async {
    lastMessage = event.newLastMessage;
    isLastMessageRead =
        false; // Set the last message to unread when a new one is sent
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  Future<void> _lastMessageReadStatusChanged(LastMessageReadStatusChanged event,
      Emitter<ConvoInstanceState> emit) async {
    isLastMessageRead = event.isRead;
    emit(ConvoInstanceLoaded(
        convoName, convoPicUrl, lastMessage, isLastMessageRead));
  }

  @override
  Future<void> close() {
    _convoListSubscription.cancel();
    return super.close();
  }
}
