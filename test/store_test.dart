import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';


void runTests(userId) {
  test('initialize store', () async {
    await API().store().initializeStore();
  });

  test('Ensure members are filled', () async {
    final int length = API().store().getAllMembers().length;
    print(length);
    expect(length != 0, true);
  });

  test('Add member and check store updated', () async {
    final int previousLength = API().store().getAllMembers().length;

    Document<MemberData> member = API().members().add(MemberData()..name = '');
    await Future.delayed(const Duration(seconds: 1));

    expect(API().store().getAllMembers().length, previousLength + 1);

    API().members().delete(member.id, member);
    await Future.delayed(const Duration(seconds: 1));

    expect(API().store().getAllMembers().length, previousLength);
  });
}
