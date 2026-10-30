/// Supplies the in-memory access token issued by TheOff1ceAuth to other
/// services (TheOff1ceAI verifies it with Auth's public key).
abstract interface class AccessTokenSource {
  /// Returns a token that is not about to expire, or `null` without a session.
  /// [forceRefresh] rotates it first (used after a 401 from another service).
  Future<String?> currentAccessToken({bool forceRefresh = false});
}
