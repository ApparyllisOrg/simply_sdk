class Connection {
  String currentHost = "http://localhost:3000";

  void setCurrentHost(String host) {
    assert(host != null);
    assert(host.isNotEmpty);
    currentHost = host;
  }

  String collectionGet() => "$currentHost/collection/get";
  String documentGet() => "$currentHost/document/get";
  String documentAdd() => "$currentHost/document/add";
  String documentUpdate() => "$currentHost/document/update";
  String documentDelete() => "$currentHost/document/delete";
  String batch() => "$currentHost/collection/batch";
}
