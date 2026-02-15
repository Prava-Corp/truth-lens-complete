import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication service wrapping Supabase Auth
class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Expose Supabase client for direct DB queries (scan history, etc.)
  static SupabaseClient get client => _client;

  /// Get current user's ID
  static String? get userId => _client.auth.currentUser?.id;

  /// Check if a user is currently logged in
  static bool get isLoggedIn => _client.auth.currentSession != null;

  /// Get current user's email
  static String? get userEmail => _client.auth.currentUser?.email;

  /// Stream of auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
