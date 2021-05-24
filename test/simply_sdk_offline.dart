import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:simply_sdk/document.dart';

import '../lib/simply_sdk.dart';

Future<List<String>> addDocs(int count, int maxRandom) {
  return Future(() async {
    List<String> docIds = [];

    for (int i = 0; i < count; i++) {
      String id = ObjectId(clientMode: true).$oid;

      String receivedId = await API()
          .cache()
          .insertDocument("test", id, {"number": Random().nextInt(maxRandom)});

      expect(id, receivedId);

      docIds.add(receivedId);
    }

    List<Document> docs =
        await API().cache().searchForDocuments("test", {}, "");

    expect(docs.length, count);
    return docIds;
  });
}

void main() {
  test('add 20 documents', () async {
    await API().initialize();
    await API().cache().clear();
    await addDocs(20, 50);
  });

  test('add 20 documents and remove all 20 documents', () async {
    await API().cache().clear();
    List<String> docs = await addDocs(20, 50);

    expect(docs.length, 20);

    for (var i = 0; i < docs.length; i++) {
      print(docs[i]);
      await API().cache().removeDocument("test", docs[i]);
    }

    List<Document> afterDocs =
        await API().cache().searchForDocuments("test", {}, "");

    expect(afterDocs.length, 0);
  });

  test('add 20 documents and query all 20 documents and order by', () async {
    await API().cache().clear();
    List<String> docs = await addDocs(20, 50);

    expect(docs.length, 20);

    List<Document> afterDocs =
        await API().cache().searchForDocuments("test", {}, "number");

    int lastNum = -999;

    for (var doc in afterDocs) {
      print(doc.data);
      expect(lastNum <= doc.data["number"], true);
      lastNum = doc.data["number"];
    }

    expect(afterDocs.length, 20);
  });
}
