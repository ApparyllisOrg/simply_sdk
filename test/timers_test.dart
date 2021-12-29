import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/automatedTimers.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/api/notes.dart';
import 'package:simply_sdk/api/repeatedTimers.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

void runTests(userId) {
  test('add repeated timer', () async {
    API().repeatedTimers().add(RepeatedTimerData()
      ..name = "Hello"
      ..message = "testMemberId"
      ..startTime = (RepeatedTimerStartTimeData()
        ..day = 0
        ..month = 0
        ..year = 2021)
      ..time = (RepeatedTimerTimeData()
        ..hour = 0
        ..minute = 0)
      ..dayInterval = 1);
    await Future.delayed(Duration(seconds: 1));
  });

  test('add automated timer', () async {
    API().automatedTimers().add(AutomatedTimerData()
      ..name = "Hello"
      ..message = "testMemberId"
      ..type = 0
      ..action = 0
      ..delayInHours = 5);
    await Future.delayed(Duration(seconds: 1));
  });

  test('updated repeated timer', () async {
    List<Document<RepeatedTimerData>> timers = await API().repeatedTimers().getAll();
    API().repeatedTimers().update(
        timers[0].id,
        RepeatedTimerData()
          ..name = "Hello"
          ..message = "testMemberId");
    await Future.delayed(Duration(seconds: 1));
  });

  test('updated automated timer', () async {
    List<Document<AutomatedTimerData>> timers = await API().automatedTimers().getAll();
    API().automatedTimers().update(
        timers[0].id,
        AutomatedTimerData()
          ..name = "Hello"
          ..message = "testMemberId");
    await Future.delayed(Duration(seconds: 1));
  });

  test('verify timer count', () async {
    List<Document<AutomatedTimerData>> automatedTimers = await API().automatedTimers().getAll();
    List<Document<RepeatedTimerData>> repeatedTimers = await API().repeatedTimers().getAll();
    expect(automatedTimers.length, 1);
    expect(repeatedTimers.length, 1);
  });

  test('delete timers', () async {
    List<Document<AutomatedTimerData>> automatedTimers = await API().automatedTimers().getAll();
    List<Document<RepeatedTimerData>> repeatedTimers = await API().repeatedTimers().getAll();
    API().automatedTimers().delete(automatedTimers[0].id, automatedTimers[0]);
    API().repeatedTimers().delete(repeatedTimers[0].id, repeatedTimers[0]);
    await Future.delayed(Duration(seconds: 1));
  });

  test('verify timer count', () async {
    List<Document<AutomatedTimerData>> automatedTimers = await API().automatedTimers().getAll();
    List<Document<RepeatedTimerData>> repeatedTimers = await API().repeatedTimers().getAll();
    expect(automatedTimers.length, 0);
    expect(repeatedTimers.length, 0);
  });
}
