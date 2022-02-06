class Auth {
  String? _lastToken;
  String? _lastUid;

  List<Function?> onAuthChange = [];

  late Function _getAuth;

  void setLastAuthToken(String newToken, String newUid) {
    assert(newToken.isNotEmpty);
    assert(newUid.isNotEmpty);

    bool changed = _lastToken != newToken || _lastUid != newUid;

    _lastToken = newToken;
    _lastUid = newUid;

    if (changed) {
      onAuthChange.forEach((element) {
        if (element != null) {
          element();
        }
      });
    }
  }

  void invalidateToken() {
    _lastToken = null;
    _lastUid = null;

    onAuthChange.forEach((element) {
      if (element != null) {
        element();
      }
    });
  }

  void setGetAuth(Function getAuth) {
    _getAuth = getAuth;
  }

  String? getToken() => _lastToken;
  String? getUid() => _lastUid;
  Future<bool> isAuthenticated() {
    return Future(() async {
      var result = await _getAuth();
      if (result['success']) {
        setLastAuthToken(result['token'], result['uid']);
        return true;
      } else {
        invalidateToken();
        return false;
      }
    });
  }
}
