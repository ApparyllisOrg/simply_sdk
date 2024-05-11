import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

import 'simply_sdk_test.dart';

void runTests(userId) {
  final int now = DateTime.now().millisecondsSinceEpoch;
  final int end = now + (60 * 1000);
  test('Remove everyone from front', () async {
    List<Document<FrontHistoryData>> fronters = API().store().getFronters();
    for (int i = fronters.length - 1; i >= 0; --i) {
      API().frontHistory().update(
          fronters[i].id,
          FrontHistoryData()
            ..live = false
            ..endTime = end);
    }
    await Future.delayed(const Duration(seconds: 2));
  });

  test('Add to front', () async {
    API().frontHistory().add(FrontHistoryData()
      ..live = true
      ..custom = false
      ..startTime = now
      ..member = 'testMember');
  });

  test('Update front', () async {
    Document<FrontHistoryData> fhDoc = API().store().getFronters()[0];

    final String randomMember = getRandString(10);

    API().frontHistory().update(
        fhDoc.id,
        FrontHistoryData()
          ..live = true
          ..member = randomMember);

    Document<FrontHistoryData> updatedFhDoc = API().store().getFronterById(randomMember)!;

    expect(updatedFhDoc.dataObject.member, randomMember);

    expect(API().store().getFronters().length, 1);
  });

  test('Add another to front', () async {
    API().frontHistory().add(FrontHistoryData()
      ..live = true
      ..custom = false
      ..startTime = now
      ..member = 'testMember2');
    await Future.delayed(const Duration(seconds: 1));
  });

  test('Check amount of people in front', () async {
    expect(API().store().getFronters().length, 2);
  });

  test('Remove first member from front', () async {
    API().frontHistory().update(
        API().store().getFronters()[0].id,
        FrontHistoryData()
          ..live = false
          ..endTime = end);
    await Future.delayed(const Duration(seconds: 3));
  });

  test('Check again amount of people in front', () async {
    expect(API().store().getFronters().length, 1);
  });

  test('Check found front history for range of unit test', () async {
    List<Document<FrontHistoryData>> fh = await API().frontHistory().getFrontHistoryInRange(now, end);
    expect(fh.length, 1);
  });
}
