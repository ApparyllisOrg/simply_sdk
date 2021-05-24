import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/batch.dart';
import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/document.dart';
import 'package:simply_sdk/simply_sdk.dart';

void main() {
  test('Set auth token', () async {
    await API().initialize();
    API().auth().setLastAuthToken(
        "eyJhbGciOiJSUzI1NiIsImtpZCI6IjUzNmRhZWFiZjhkZDY1ZDRkZTIxZTgyNGI4OTlhMWYzZGEyZjg5NTgiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZnJvbnRpbWUtN2FhY2UiLCJhdWQiOiJmcm9udGltZS03YWFjZSIsImF1dGhfdGltZSI6MTYyMTQ1MTE0NiwidXNlcl9pZCI6InpkaEU4TFNZaGVQOWRHemR3S3p5OGVvSnJUdTEiLCJzdWIiOiJ6ZGhFOExTWWhlUDlkR3pkd0t6eThlb0pyVHUxIiwiaWF0IjoxNjIxNDUxMTQ2LCJleHAiOjE2MjE0NTQ3NDYsImVtYWlsIjoiZGVtb0BhcHBhcnlsbGlzLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJkZW1vQGFwcGFyeWxsaXMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.ZQBE-i8F5-fsJ4bsL--w0-HWYNMdxleVTLWzjWDv4ME4ZrDnACZrHoY_96Q64_KAn2pWpP4rUAZldsx-fU7vK2quRZaEiPM1fyN_tBW1QS5uF6Ow6EySvXeC2zGT0w4Wf-6gfFnzXkg3mBIawp2xId_qRqbJfkIO4V8b2f-cM5FPQWnjwFk_H17hNycnnfenbOp_XyknlZ5iB_pY-MPGEzZcSeIL_Qd6ybAyCezBRi7uE1CNk3ULtxC0vO7t4wveqqnoPTVC3RNkeyJqVacA2_2EnwD_1m5-DxCAjpS-eLmZgso1rorvSoTM9b0ocXMXvFQseuel7IyjTZD8ExXzwQ",
        "zdhE8LSYheP9dGzdwKzy8eoJrTu1");
  });
  test('Get test', () async {
    var results = await API().database().collection("unitTest").get();
    print("Returned ${results.length} results");
  });

  // fill up the database
  test('add 1000 documents', () async {
    return;
    for (int i = 0; i < 1000; i++) {
      API()
          .database()
          .collection("unitTest")
          .add({"number": Random().nextInt(100)});
    }
  });
  test('get test with query equal 0', () async {
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

  test('get test with query not equal to 50', () async {
    var results = await API()
        .database()
        .collection("unitTest")
        .where({"number": Query(isNotEqualTo: 50)}).get();
    for (var result in results) {
      bool notEqual50 = result.data["number"] != 50;
      expect(notEqual50, true);
    }
    print("Returned ${results.length} results");
  });

  test('test add, update and delete of the same document', () async {
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
    var results =
        await API().database().collection("unitTest").orderBy("number").get();
    var lastNumber = -9999;
    for (var result in results) {
      print(result.data);
      bool largerOrEqual = result.data["number"] >= lastNumber;
      lastNumber = result.data["number"];
      expect(largerOrEqual, true);
    }
  });

  test('get test with query order by number, limit to first 10', () async {
    var results = await API()
        .database()
        .collection("unitTest")
        .orderBy("number")
        .limit(10)
        .get();
    var lastNumber = -9999;
    for (var result in results) {
      print(result.data);
      bool largerOrEqual = result.data["number"] >= lastNumber;
      lastNumber = result.data["number"];
      expect(largerOrEqual, true);
    }

    bool lessOrEqualTo10Results = results.length <= 10;
    expect(lessOrEqualTo10Results, true);
  });

  test(
      'get test with query order by number, limit to first 5 after starting at pos 5',
      () async {
    var results = await API()
        .database()
        .collection("unitTest")
        .orderBy("number")
        .limit(5)
        .start(5)
        .get();
    var lastNumber = -9999;
    for (var result in results) {
      print(result.data);
      bool largerOrEqual = result.data["number"] >= lastNumber;
      lastNumber = result.data["number"];
      expect(largerOrEqual, true);
    }

    bool lessOrEqualTo5Results = results.length <= 5;
    expect(lessOrEqualTo5Results, true);
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
    batch.add({"number": rand});
    batch.add({"number": rand});
    batch.add({"number": rand});
    await batch.commit();
  });
}
