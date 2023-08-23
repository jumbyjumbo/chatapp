import 'package:flutter_bloc/flutter_bloc.dart';
import 'authevent.dart';
import 'authservice.dart';
import 'authstate.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<UserLoggedIn>(_onUserLoggedIn);
    on<UserLoggedOut>(_onUserLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final currentUser = _authService.firebaseAuth.currentUser;
    if (currentUser == null) {
      emit(Unauthenticated());
    } else {
      final userData =
          await _authService.usersCollection.doc(currentUser.uid).get();
      final data = userData.data() as Map<String, dynamic>;
      if (data['username'] == null || data['username'] == "") {
        emit(UsernameNotSet());
      } else {
        emit(Authenticated());
      }
    }
  }

  void _onUserLoggedIn(UserLoggedIn event, Emitter<AuthState> emit) async {
    bool isSuccess = await _authService.signInWithGoogle();
    if (isSuccess) {
      //get user
      final currentUser = _authService.firebaseAuth.currentUser;
      //get their data
      final userData =
          await _authService.usersCollection.doc(currentUser!.uid).get();
      //get the data as a map
      final data = userData.data() as Map<String, dynamic>;
      //check their username
      if (data['username'] == null || data['username'] == "") {
        emit(UsernameNotSet());
      } else {
        emit(Authenticated());
      }
    }
  }

  Future<void> _onUserLoggedOut(
      UserLoggedOut event, Emitter<AuthState> emit) async {
    //logout
    await _authService.signOutUser();
    //tell authbloc that user is logged out
    emit(Unauthenticated());
  }
}
