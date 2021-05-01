class Auth {
  String lastToken;

  void setLastAuthToken(String newToken) {
    assert(newToken != null);
    assert(newToken.isNotEmpty);
    lastToken = newToken;
  }

  void invalidateToken() {
    lastToken = null;
  }

  String getToken() => lastToken;
  bool isAuthenticated() => lastToken != null;
}
