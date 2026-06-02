import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

    // 1. Tenta login nativo no Android e iOS
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        developer.log('AuthCubit: Mobile platform detected. Attempting native Google Sign-in...', name: 'AuthCubit');
        final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
        final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

        final googleSignIn = GoogleSignIn(
          clientId: iosClientId,
          serverClientId: webClientId,
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          developer.log('AuthCubit: Native Google Sign-in cancelled by user.', name: 'AuthCubit');
          emit(const UserAuthInitial());
          return;
        }

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null) {
          throw StateError('Não foi possível obter o ID Token do Google.');
        }

        developer.log('AuthCubit: Native Google Sign-in successful. Signing in with Supabase ID Token...', name: 'AuthCubit');
        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        developer.log('AuthCubit: Supabase sign-in with ID Token completed successfully.', name: 'AuthCubit');
        return;
      } catch (e, st) {
        developer.log(
          'AuthCubit: Native Google Sign-in failed: $e. Falling back to browser-based OAuth...',
          error: e,
          stackTrace: st,
          name: 'AuthCubit',
        );
      }
    }

    // 2. Fallback ou Desktop/Web: usa login via navegador externo
    try {
      developer.log('AuthCubit: Starting browser-based OAuth fallback with termofication://login-callback', name: 'AuthCubit');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'termofication://login-callback',
      );
      developer.log('AuthCubit: signInWithOAuth call completed', name: 'AuthCubit');
    } catch (e, st) {
      developer.log('AuthCubit: Browser OAuth error = $e', error: e, stackTrace: st, name: 'AuthCubit');
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
