import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ConvoListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConvoListInitial extends ConvoListState {}

class ConvoListLoading extends ConvoListState {}

class ConvoListLoaded extends ConvoListState {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> convos;

  ConvoListLoaded(this.convos);

  @override
  List<Object?> get props => [convos];
}
