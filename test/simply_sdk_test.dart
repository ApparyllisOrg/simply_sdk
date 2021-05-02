import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';

void main() {
  test('Set auth token', () async {
    API().auth().setLastAuthToken("unitTest");
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
}
