import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<UserAuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthCubit() : super(const UserAuthInitial()) {
    print('AuthCubit: Initializing...');
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final User? user = session?.user;
      print(
        'AuthCubit: onAuthStateChange: event = ${data.event}, session_exists = ${session != null}, user_id = ${user?.id}',
      );

      if (session != null && user != null) {
        print('AuthCubit: Emitting UserAuthAuthenticated for ${user.id}');
        emit(
          UserAuthAuthenticated(user: user, accessToken: session.accessToken),
        );
      } else {
        print('AuthCubit: No valid session. Current state = $state');
        // Se já estivermos explicitamente em modo anônimo, não reseta para Initial
        if (state is! UserAuthAnonymous) {
          print('AuthCubit: Emitting UserAuthInitial');
          emit(const UserAuthInitial());
        }
      }
    });
  }

  Future<void> loginWithGoogle() async {
    print('AuthCubit: loginWithGoogle() started');
    emit(const UserAuthLoading());
    try {
      // Abre fluxo nativo/web de OAuth usando o Supabase Auth
      print('AuthCubit: Calling signInWithOAuth with termofication://login-callback');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'termofication://login-callback',
      );
      print('AuthCubit: signInWithOAuth call completed');
    } catch (e, st) {
      print('AuthCubit: loginWithGoogle error = $e\n$st');
      emit(UserAuthError('Falha ao autenticar com o Google: ${e.toString()}'));
    }
  }

  void playAnonymously() {
    print('AuthCubit: playAnonymously() called');
    emit(const UserAuthAnonymous());
  }

  Future<void> logout() async {
    print('AuthCubit: logout() started');
    emit(const UserAuthLoading());
    try {
      print('AuthCubit: Calling signOut');
      await _supabase.auth.signOut();
      print('AuthCubit: signOut success, emitting UserAuthInitial');
      emit(const UserAuthInitial());
    } catch (e, st) {
      print('AuthCubit: logout error = $e\n$st');
      emit(UserAuthError('Erro ao sair da conta: ${e.toString()}'));
    }
  }
}
