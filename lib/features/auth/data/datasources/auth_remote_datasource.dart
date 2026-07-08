import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDatasource {
  final SupabaseClient _client;

  AuthRemoteDatasource(this._client);

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<OAuthResponse> getOAuthSignInUrl({
    required OAuthProvider provider,
    String? redirectTo,
    Map<String, String>? queryParams,
  }) {
    return _client.auth.getOAuthSignInUrl(
      provider: provider,
      redirectTo: redirectTo,
      queryParams: queryParams,
    );
  }

  Future<void> getSessionFromUrl(Uri uri) {
    return _client.auth.getSessionFromUrl(uri);
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Map<String, dynamic>? get currentUserMetadata =>
      _client.auth.currentUser?.userMetadata;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<Map<String, dynamic>?> getProfileRole(String userId) {
    return _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> upsertProfile(Map<String, dynamic> values) {
    return _client.from('profiles').upsert(values);
  }

  Future<Map<String, dynamic>?> getDoctorStatus(String userId) {
    return _client
        .from('doctors')
        .select('status')
        .eq('id', userId)
        .maybeSingle();
  }
}
