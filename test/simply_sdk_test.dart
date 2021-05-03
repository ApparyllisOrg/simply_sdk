import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/document.dart';
import 'package:simply_sdk/simply_sdk.dart';

void main() {
  test('Set auth token', () async {
    API().auth().setLastAuthToken(
        "eyJhbGciOiJSUzI1NiIsImtpZCI6ImNjM2Y0ZThiMmYxZDAyZjBlYTRiMWJkZGU1NWFkZDhiMDhiYzUzODYiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZnJvbnRpbWUtN2FhY2UiLCJhdWQiOiJmcm9udGltZS03YWFjZSIsImF1dGhfdGltZSI6MTYyMDA3NjE1NCwidXNlcl9pZCI6InpkaEU4TFNZaGVQOWRHemR3S3p5OGVvSnJUdTEiLCJzdWIiOiJ6ZGhFOExTWWhlUDlkR3pkd0t6eThlb0pyVHUxIiwiaWF0IjoxNjIwMDc2MTU0LCJleHAiOjE2MjAwNzk3NTQsImVtYWlsIjoiZGVtb0BhcHBhcnlsbGlzLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJkZW1vQGFwcGFyeWxsaXMuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.dtrazLGH77acZQMyzMrnXp5nIACxjDgXEaQvERMYNHFFE1M0LQ_fYCtUtuvtDb2nxLw3sFD74LPrW_1AiWxC1iHh-3WP0AMtZaIA52boUUKet5j2L-EMC4Q2r_dAbWuuiZP8C2Wcyo3junnysijzXjRs57WgKAnHza0onJZeEGa-E5bgMt7rnM6MelqBf0beZktbuymj7_3clQYwBdLD7AqSUSQQ6ymFN35rl6pWoJQ_d7G1N4VxGsPYmMHZPRJeeDxNC9J7JzZGHhUOi0H0PEQJW7xdQhqzBUk0MMMxPv9Hkh026DhDgiM6UszqcB7smQIXd5Ryfsy4psamG_ndnA");
  });
  test('Get test', () async {
    var results = await API().database().collection("unitTest").get();
    print("Returned ${results.length} results");
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
    var stream = API()
        .socket()
        .subscribeToCollection("unitTest", "number", Query(isSmallerThan: 50));

    var numCalls = 0;
    stream.stream.listen((var documents) {
      print(documents);
      for (Document result in documents) {
        print(result.data);
        bool smallerThan50 = result.data["number"] < 50;
        expect(smallerThan50, true);
      }

      numCalls++;
    });
    await Future.delayed(Duration(seconds: 10));
    var rand = Random().nextInt(49);
    print(rand);
    var result =
        await API().database().collection("unitTest").add({"number": rand});

    var newNum = Random().nextInt(49);
    print(newNum);
    await result.update({"number": newNum});
    await Future.delayed(Duration(seconds: 1));
    await result.delete();

    var postDeleteResult =
        await API().database().collection("unitTest").document(result.id);

    expect(postDeleteResult.exists, false);

    // After 5 seconds expect all changes to have come in...
    await Future.delayed(Duration(seconds: 5));

    // First initial return
    // Second added document
    // Third remove document
    expect(numCalls, 3);

    stream.close();
  });
}
