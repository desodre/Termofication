import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<UserAuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthCubit() : super(const UserAuthInitial()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final User? user = session?.user;

      if (session != null && user != null) {
        emit(UserAuthAuthenticated(
          user: user,
          accessToken: session.accessToken,
        ));
      } else {
        // Se já estivermos explicitamente em modo anônimo, não reseta para Initial
        if (state is! UserAuthAnonymous) {
          emit(const UserAuthInitial());
        }
      }
    });
  }

  Future<void> loginWithGoogle() async {
    emit(const UserAuthLoading());
    try {
      // Abre fluxo nativo/web de OAuth usando o Supabase Auth
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'termofication://login-callback',
      );
    } catch (e) {
      emit(UserAuthError('Falha ao autenticar com o Google: ${e.toString()}'));
    }
  }

  void playAnonymously() {
    emit(const UserAuthAnonymous());
  }

  Future<void> logout() async {
    emit(const UserAuthLoading());
    try {
      await _supabase.auth.signOut();
      emit(const UserAuthInitial());
    } catch (e) {
      emit(UserAuthError('Erro ao sair da conta: ${e.toString()}'));
    }
  }
}
