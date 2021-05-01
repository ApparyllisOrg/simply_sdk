String mapToQueryString(Map<String, dynamic> map) {
  assert(map != null);
  String query = "?";
  for (var key in map.keys) {
    query = query + key + "=" + map[key].toString() + "&";
  }
}
