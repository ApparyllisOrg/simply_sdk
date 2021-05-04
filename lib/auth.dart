class Auth {
  String _lastToken;
  String _lastUid;

  void setLastAuthToken(String newToken, String newUid) {
    assert(newToken != null);
    assert(newToken.isNotEmpty);
    assert(newUid != null);
    assert(newUid.isNotEmpty);

    _lastToken = newToken;
    _lastUid = newUid;
  }

  void invalidateToken() {
    _lastToken = null;
    _lastUid = null;
  }

  String getToken() => _lastToken;
  String getUid() => _lastUid;
  bool isAuthenticated() => _lastToken != null;
}
