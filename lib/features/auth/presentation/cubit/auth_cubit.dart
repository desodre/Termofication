import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<UserAuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthCubit() : super(const UserAuthInitial()) {
    developer.log('AuthCubit: Initializing...', name: 'AuthCubit');
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final User? user = session?.user;
      developer.log(
        'AuthCubit: onAuthStateChange: event = ${data.event}, session_exists = ${session != null}, user_id = ${user?.id}',
        name: 'AuthCubit',
      );

      if (session != null && user != null) {
        developer.log('AuthCubit: Emitting UserAuthAuthenticated for ${user.id}', name: 'AuthCubit');
        emit(
          UserAuthAuthenticated(user: user, accessToken: session.accessToken),
        );
      } else {
        developer.log('AuthCubit: No valid session. Current state = $state', name: 'AuthCubit');
        // Se já estivermos explicitamente em modo anônimo, não reseta para Initial
        if (state is! UserAuthAnonymous) {
          developer.log('AuthCubit: Emitting UserAuthInitial', name: 'AuthCubit');
          emit(const UserAuthInitial());
        }
      }
    });
  }

  Future<void> loginWithGoogle() async {
    developer.log('AuthCubit: loginWithGoogle() started', name: 'AuthCubit');
    emit(const UserAuthLoading());
    try {
      // Abre fluxo nativo/web de OAuth usando o Supabase Auth
      developer.log('AuthCubit: Calling signInWithOAuth with termofication://login-callback', name: 'AuthCubit');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'termofication://login-callback',
      );
      developer.log('AuthCubit: signInWithOAuth call completed', name: 'AuthCubit');
    } catch (e, st) {
      developer.log('AuthCubit: loginWithGoogle error = $e', error: e, stackTrace: st, name: 'AuthCubit');
      emit(UserAuthError('Falha ao autenticar com o Google: ${e.toString()}'));
    }
  }

  void playAnonymously() {
    developer.log('AuthCubit: playAnonymously() called', name: 'AuthCubit');
    emit(const UserAuthAnonymous());
  }

  Future<void> logout() async {
    developer.log('AuthCubit: logout() started', name: 'AuthCubit');
    emit(const UserAuthLoading());
    try {
      developer.log('AuthCubit: Calling signOut', name: 'AuthCubit');
      await _supabase.auth.signOut();
      developer.log('AuthCubit: signOut success, emitting UserAuthInitial', name: 'AuthCubit');
      emit(const UserAuthInitial());
    } catch (e, st) {
      developer.log('AuthCubit: logout error = $e', error: e, stackTrace: st, name: 'AuthCubit');
      emit(UserAuthError('Erro ao sair da conta: ${e.toString()}'));
    }
  }
}
