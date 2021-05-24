import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/document.dart';

import '../lib/simply_sdk.dart';

void main() {
  test('add 20 documents', () async {
    await API().initialize();
    await API().cache().clear();
    for (int i = 0; i < 20; i++) {
      var key = await API()
          .cache()
          .insertDocument("test", {"number": Random().nextInt(50)});
      print(key.toString());
    }
    List<Document> docs = await API().cache().searchForDocuments("test", {});
    expect(docs.length, 20);
  });
}
