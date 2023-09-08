import 'package:equatable/equatable.dart';

abstract class ConvoInstanceState extends Equatable {
  const ConvoInstanceState();

  @override
  List<Object> get props => [];
}

class ConvoInstanceInitial extends ConvoInstanceState {}

class ConvoInstanceLoading extends ConvoInstanceState {}

class ConvoInstanceLoaded extends ConvoInstanceState {
  final String convoName;
  final String convoPicUrl;
  final String lastMessage;
  final bool isLastMessageRead;

  const ConvoInstanceLoaded(this.convoName, this.convoPicUrl, this.lastMessage,
      this.isLastMessageRead);

  // Add copyWith method for easier state updating
  ConvoInstanceLoaded copyWith({
    String? convoName,
    String? convoPicUrl,
    String? lastMessage,
    bool? isLastMessageRead,
  }) {
    return ConvoInstanceLoaded(
      convoName ?? this.convoName,
      convoPicUrl ?? this.convoPicUrl,
      lastMessage ?? this.lastMessage,
      isLastMessageRead ?? this.isLastMessageRead,
    );
  }
}
