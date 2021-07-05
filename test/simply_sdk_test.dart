import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as fir;
import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/batch.dart';
import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/document.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:mongo_dart/mongo_dart.dart';

void setAuth() async {
  await API().initialize();
  API().auth().setGetAuth(() async {
    return {
      "success": true,
      "token":
          "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg4ZGYxMzgwM2I3NDM2NjExYWQ0ODE0NmE4ZGExYjA3MTg2ZmQxZTkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZnJvbnRpbWUtN2FhY2UiLCJhdWQiOiJmcm9udGltZS03YWFjZSIsImF1dGhfdGltZSI6MTYyNDc4MTM5NiwidXNlcl9pZCI6InJYSDV4bGllRk9aNHVscUFsTHYzWVhMbW41MzIiLCJzdWIiOiJyWEg1eGxpZUZPWjR1bHFBbEx2M1lYTG1uNTMyIiwiaWF0IjoxNjI0NzgxMzk2LCJleHAiOjE2MjQ3ODQ5OTYsImVtYWlsIjoiY2F0aGVyZWNlbHZpY3RvcmlhQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7Imdvb2dsZS5jb20iOlsiMTA2NDc3NTY3MTY0NDQzODYyMjI1Il0sImFwcGxlLmNvbSI6WyIwMDExNzUuMGEyMTI5ZDdjM2E3NDc2MThiOTQzZGMwZWZkZDM0ZjEuMTk1NCJdLCJlbWFpbCI6WyJjYXRoZXJlY2VsdmljdG9yaWFAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.G0QuznZY6khBCJWXGFBspRaSgN_Pa6ouNOHwWO6UDxEOeHLsRYnbhdiJD0zdnxXWSJv38o3fKv4VpsqJJ_WOXrgCSJBTAMy0g-fIyLKrAdxI_dU8B2Hk94Ug4zSo_gvY4f6Y0N0DN_maLx8sCQAEFXsv601X4B8FxliDo6K_vCXi-wg1Ui_8lHvWujbPiBiWSW-KXIzWwEz4L_-U9Fg6Kot1n4zMRF3dU_hXT7bM04Ip1OWSnxBFP8jItuWhUpJRMSNOCpk3vwTTkKjtaYwwmIVGiAi7_",
      "uid": "zdhE8LSYheP9dGzdwKzy8eoJrTu1"
    };
  });
}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<String>> addDocs(int count, int maxRandom) {
    return Future(() async {
      List<String> docIds = [];

      for (int i = 0; i < count; i++) {
        String id = ObjectId(clientMode: true).$oid;

        String receivedId = await API().cache().insertDocument(
            "test", id, {"number": Random().nextInt(maxRandom)});
        await API().cache().insertDocument(
            "unitTest", id, {"number": Random().nextInt(maxRandom)});

        expect(id, receivedId);

        docIds.add(receivedId);
      }

      List<Document> docs =
          await API().cache().searchForDocuments("test", {}, "");

      expect(docs.length, count);
      return docIds;
    });
  }

  void auth() {
    API().auth().setGetAuth(() async {
      return {
        "success": true,
        "token":
            "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg4ZGYxMzgwM2I3NDM2NjExYWQ0ODE0NmE4ZGExYjA3MTg2ZmQxZTkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZnJvbnRpbWUtN2FhY2UiLCJhdWQiOiJmcm9udGltZS03YWFjZSIsImF1dGhfdGltZSI6MTYyNDc4MTM5NiwidXNlcl9pZCI6InJYSDV4bGllRk9aNHVscUFsTHYzWVhMbW41MzIiLCJzdWIiOiJyWEg1eGxpZUZPWjR1bHFBbEx2M1lYTG1uNTMyIiwiaWF0IjoxNjI0NzgxMzk2LCJleHAiOjE2MjQ3ODQ5OTYsImVtYWlsIjoiY2F0aGVyZWNlbHZpY3RvcmlhQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7Imdvb2dsZS5jb20iOlsiMTA2NDc3NTY3MTY0NDQzODYyMjI1Il0sImFwcGxlLmNvbSI6WyIwMDExNzUuMGEyMTI5ZDdjM2E3NDc2MThiOTQzZGMwZWZkZDM0ZjEuMTk1NCJdLCJlbWFpbCI6WyJjYXRoZXJlY2VsdmljdG9yaWFAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.G0QuznZY6khBCJWXGFBspRaSgN_Pa6ouNOHwWO6UDxEOeHLsRYnbhdiJD0zdnxXWSJv38o3fKv4VpsqJJ_WOXrgCSJBTAMy0g-fIyLKrAdxI_dU8B2Hk94Ug4zSo_gvY4f6Y0N0DN_maLx8sCQAEFXsv601X4B8FxliDo6K_vCXi-wg1Ui_8lHvWujbPiBiWSW-KXIzWwEz4L_-U9Fg6Kot1n4zMRF3dU_hXT7bM04Ip1OWSnxBFP8jItuWhUpJRMSNOCpk3vwTTkKjtaYwwmIVGiAi7_",
        "uid": "zdhE8LSYheP9dGzdwKzy8eoJrTu1"
      };
    });
  }

  test('Set auth token', () async {
    await API().initialize();
    auth();
  });

  test('Intialize db', () async {
    await API().initialize();
  });

  test('Test DateTime', () async {
    await API().initialize();
    auth();

    await API()
        .cache()
        .insertDocument("test", "teststet", {"startTime": DateTime.now()});
    var files = await API().cache().searchForDocuments(
        "test",
        {
          "startTime":
              Query(isLargerThan: DateTime.now().millisecondsSinceEpoch)
        },
        "");
  });

  test('add 20 documents', () async {
    await API().initialize();
    auth();
    API().connection().setDebugMode(false);
    auth();
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

  test('add 40 documents and query all 40 documents in 2 steps and order by',
      () async {
    await API().cache().clear();
    List<String> docs = await addDocs(40, 50);

    expect(docs.length, 40);

    List<Document> previous = await API()
        .cache()
        .searchForDocuments("test", {}, "number", start: 0, end: 10);

    int lastNum = -999;

    for (var doc in previous) {
      print(doc.data);
      expect(lastNum <= doc.data["number"], true);
      lastNum = doc.data["number"];
    }

    List<Document> afterDocs = await API()
        .cache()
        .searchForDocuments("test", {}, "number", start: 10, end: 20);

    for (var doc in afterDocs) {
      print(doc.data);
      expect(lastNum <= doc.data["number"], true);
      lastNum = doc.data["number"];
    }

    expect(afterDocs.length, 10);
  });

  test('Test offline simple add, update and get', () async {
    await setAuth();

    var doc = await API()
        .database()
        .collection("test")
        .add({"number": Random().nextInt(50)});

    var newDoc = await API().database().collection("test").document(doc.id);

    Map<String, dynamic> newData = {"number": Random().nextInt(50)};

    await newDoc.update(newData);

    var updatedDoc = await API().database().collection("test").document(doc.id);

    expect(updatedDoc.exists, true);
    expect(newDoc.exists, true);
    expect(doc.id, newDoc.id);
    // We can't expect this for the data to be equal because the server returns "lastUpdate", so when we're
    // not actually offline, this expect would fail.
    expect(updatedDoc.data["number"], newData["number"]);
    expect(doc.collectionId, newDoc.collectionId);
  });

  test('Test offline simple add and get', () async {
    await setAuth();

    var doc = await API()
        .database()
        .collection("test")
        .add({"number": Random().nextInt(50)});

    var newDoc = await API().database().collection("test").document(doc.id);

    expect(doc.exists, true);
    expect(newDoc.exists, true);
    expect(doc.id, newDoc.id);
    // We can't expect this for the data to be equal because the server returns "lastUpdate", so when we're
    // not actually offline, this expect would fail.
    expect(doc.data["number"], newDoc.data["number"]);
    expect(doc.collectionId, newDoc.collectionId);
  });

  test('Test Timestamp encode and decode', () async {
    await setAuth();

    fir.Timestamp now = fir.Timestamp.now();

    var doc = await API().database().collection("codecTest").add({"time": now});

    var newDoc =
        await API().database().collection("codecTest").document(doc.id);

    print(doc.id);

    print(newDoc.data.toString());
    print(newDoc.value<fir.Timestamp>("time", null));

    expect(doc.exists, true);
    expect(newDoc.exists, true);
    expect(doc.id, newDoc.id);
    expect(now, newDoc.value<fir.Timestamp>("time", null));
    expect(doc.collectionId, newDoc.collectionId);
  });

  test('Test Datetime encode and decode', () async {
    await setAuth();
    DateTime now = DateTime.now();

    var doc = await API().database().collection("codecTest").add({"time": now});

    var newDoc =
        await API().database().collection("codecTest").document(doc.id);

    print(doc.id);

    print(newDoc.data.toString());
    print(newDoc.value<fir.Timestamp>("time", null));

    expect(doc.exists, true);
    expect(newDoc.exists, true);
    expect(doc.id, newDoc.id);
    expect(
        fir.Timestamp.fromDate(now), newDoc.value<fir.Timestamp>("time", null));
    expect(doc.collectionId, newDoc.collectionId);
  });

  test("Send enqued changes to server", () async {
    await setAuth();
    String id = ObjectId(clientMode: true).$oid;
    API().cache().queueAdd("test", id, {"exists": true});
    API().cache().queueUpdate("test", id, {"exists": false});
    API().cache().queueDelete("test", id);
  });

  test('Get test', () async {
    await setAuth();

    var results = await API().database().collection("unitTest").get();
    print("Returned ${results.length} results");
  });

  // fill up the database
  test('add 1000 documents', () async {
    await setAuth();

    for (int i = 0; i < 1000; i++) {
      API()
          .database()
          .collection("unitTest")
          .add({"number": Random().nextInt(100)});
    }
  });
  test('get test with query equal 0', () async {
    await setAuth();

    var results = await API()
        .database()
        .collection("unitTest")
        .where({"number": Query(isEqualTo: 0)}).get();
    for (var result in results) {
      bool equals0 = result.data["number"] == 0;
      expect(equals0, true);
    }
    print("Returned ${results.length} results");
  });

  test('get test with query larger than 50', () async {
    await setAuth();
    var results = await API()
        .database()
        .collection("unitTest")
        .where({"number": Query(isLargerThan: 50)}).get();
    for (var result in results) {
      bool largerThan50 = result.data["number"] > 50;
      expect(largerThan50, true);
    }
    print("Returned ${results.length} results");
  });

  test('get test with query smaller than 50', () async {
    await setAuth();
    var results = await API()
        .database()
        .collection("unitTest")
        .where({"number": Query(isSmallerThan: 50)}).get();
    for (var result in results) {
      bool smallerThan50 = result.data["number"] < 50;
      expect(smallerThan50, true);
    }
    print("Returned ${results.length} results");
  });

  test('get test with query not equal to 0', () async {
    await setAuth();
    var results = await API()
        .database()
        .collection("unitTest")
        .where({"number": Query(isNotEqualTo: 0)}).get();
    for (var result in results) {
      bool notEqual50 = result.data["number"] != 0;
      expect(notEqual50, true);
    }
    print("Returned ${results.length} results");
  });

  test('test add, update and delete of the same document', () async {
    auth();
    var result = await API()
        .database()
        .collection("unitTest")
        .add({"number": Random().nextInt(100)});

    var newNum = Random().nextInt(100);
    await result.update({"number": newNum});

    var getResult =
        await API().database().collection("unitTest").document(result.id);

    print(getResult.data);
    expect(getResult.data["number"], newNum);

    await getResult.delete();

    var postDeleteResult =
        await API().database().collection("unitTest").document(result.id);

    expect(postDeleteResult.exists, false);
  });

  test('get test with query order by number', () async {
    auth();
    var results = await API()
        .database()
        .collection("unitTest")
        .orderBy("number", 1)
        .get();
    var lastNumber = -9999;
    for (var result in results) {
      print(result.data);
      bool largerOrEqual = result.data["number"] >= lastNumber;
      lastNumber = result.data["number"];
      expect(largerOrEqual, true);
    }
  });

  test('get test with query order by number, limit to first 10', () async {
    await setAuth();
    await addDocs(40, 50);
    var results = await API()
        .database()
        .collection("unitTest")
        .orderBy("number", 1)
        .limit(10)
        .get();
    var lastNumber = -9999;
    for (var result in results) {
      print(result.data);
      bool largerOrEqual = result.data["number"] >= lastNumber;
      lastNumber = result.data["number"];
      expect(largerOrEqual, true);
    }

    expect(results.length, 10);
  });

  test(
      'get test with query order by number, limit to first 5 after starting at pos 5',
      () async {
    await setAuth();
    await addDocs(40, 50);
    var results = await API()
        .database()
        .collection("unitTest")
        .orderBy("number", 1)
        .limit(5)
        .start(0)
        .get();
    var lastNumber = -9999;
    for (var result in results) {
      print(result.data);
      bool largerOrEqual = result.data["number"] >= lastNumber;
      lastNumber = result.data["number"];
      expect(largerOrEqual, true);
    }

    expect(results.length, 5);
  });

  test('Subscribe to changes in namespace unitTest', () async {
    var stream = await API().socket().subscribeToCollection(
        "unitTest", {"number": Query(isSmallerThan: 50)});

    var numCalls = 0;

    stream.stream.listen((var documents) {
      for (Document result in documents) {
        bool smallerThan50 = result.data["number"] < 50;
        expect(smallerThan50, true);
      }

      numCalls++;
    });

    stream.onResume = () async {
      await Future.delayed(Duration(seconds: 2));
      var rand = Random().nextInt(49);
      var result =
          await API().database().collection("unitTest").add({"number": rand});

      var newNum = Random().nextInt(49);
      await result.update({"number": newNum});
      await Future.delayed(Duration(seconds: 1));
      await result.delete();

      var postDeleteResult =
          await API().database().collection("unitTest").document(result.id);
      expect(postDeleteResult.exists, false);
    };

    // After 10 seconds expect all changes to have come in...
    await Future.delayed(Duration(seconds: 10));

    // First initial return
    // Second added document
    // Third update document
    // Fourth delete document
    expect(numCalls, 4);

    stream.close();
  });

  test('Batch write', () async {
    Batch batch = API().database().batch("unitTest");
    var rand = Random().nextInt(100);
    rand += 1000;
    batch.add(ObjectId(clientMode: true).$oid, {"number": rand});
    batch.add(ObjectId(clientMode: true).$oid, {"number": rand});
    batch.add(ObjectId(clientMode: true).$oid, {"number": rand});
    await batch.commit();
  });
}
