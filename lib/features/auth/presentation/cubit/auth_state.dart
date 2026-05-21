import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserAuthState {
  const UserAuthState();
}

class UserAuthInitial extends UserAuthState {
  const UserAuthInitial();
}

class UserAuthLoading extends UserAuthState {
  const UserAuthLoading();
}

class UserAuthAuthenticated extends UserAuthState {
  final User user;
  final String accessToken;
  const UserAuthAuthenticated({required this.user, required this.accessToken});
}

class UserAuthAnonymous extends UserAuthState {
  const UserAuthAnonymous();
}

class UserAuthError extends UserAuthState {
  final String message;
  const UserAuthError(this.message);
}
