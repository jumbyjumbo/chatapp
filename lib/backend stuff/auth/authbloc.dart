import 'package:flutter_bloc/flutter_bloc.dart';
import 'authevent.dart';
import 'authservice.dart';
import 'authstate.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final currentUser = _authService.firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(Unauthenticated());
      } else {
        final userData =
            await _authService.usersCollection.doc(currentUser.uid).get();
        if (userData['username'] == null) {
          emit(UsernameNotSet());
        } else {
          emit(Authenticated());
        }
      }
    });

    on<UserLoggedIn>((event, emit) => emit(Authenticated()));

    on<UserLoggedOut>((event, emit) async {
      await _authService.signOutUser();
      emit(Unauthenticated());
    });
  }
}
