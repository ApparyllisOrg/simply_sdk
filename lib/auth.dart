class Auth {
  String _lastToken;
  String _lastUid;

  Function _getAuth;

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

  void setGetAuth(Function getAuth) {
    _getAuth = getAuth;
  }

  String getToken() => _lastToken;
  String getUid() => _lastUid;
  Future<bool> isAuthenticated() {
    return Future(() async {
      var result = await _getAuth();
      setLastAuthToken(result.token, result.uid);
      return true;
    });
  }
}
