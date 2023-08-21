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
    final currentUser = _authService.firebaseAuth.currentUser;
    if (currentUser != null) {
      final userData =
          await _authService.usersCollection.doc(currentUser.uid).get();
      final data = userData.data() as Map<String, dynamic>;
      if (data['username'] == null || data['username'] == "") {
        emit(UsernameNotSet());
      } else {
        emit(Authenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onUserLoggedOut(
      UserLoggedOut event, Emitter<AuthState> emit) async {
    print("UserLoggedOut event received");

    await _authService.signOutUser();

    if (_authService.firebaseAuth.currentUser == null) {
      print("Firebase user is null. Emitting Unauthenticated.");
      emit(Unauthenticated());
    } else {
      print(
          "Firebase user is still present after signing out. This shouldn't happen.");
    }
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    print(transition);
    super.onTransition(transition);
  }
}
