import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/api/pk.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

import 'simply_sdk_test.dart';

String pkUnitTestToken = "zsVjrLAbMii9qksAY5pxw11FO609XaCnp2LjF56p5zVRjrYCgycfHZudA3VerDnd";

void runTests(userId) {
  test('sync all members from pk', () async {
    //API().pk().syncMembersFromPk(PKSyncSettings(true, false, true, true, true, true), PKSyncAllSettings(true, true), pkUnitTestToken);
  });

  test('Update member in sp', () async {
    List<Document<MemberData>> members = await API().members().getAll();
    Document<MemberData> member = members[0];

    String randomDesc = getRandString(20);

    API().members().update(member.id, MemberData()..desc = randomDesc);
    await Future.delayed(Duration(seconds: 1));

    Document<MemberData> updatedMember = await API().members().get(member.id);
    expect(randomDesc, updatedMember.dataObject.desc);
  });

  test('sync member to pk', () async {
    List<Document<MemberData>> members = await API().members().getAll();
    Document<MemberData> member = members[0];
    API().pk().syncMemberToPk(member.id, PKSyncSettings(true, false, true, true, true, true), pkUnitTestToken);
  });

  test('sync all members to pk', () async {
    //API().pk().syncMembersToPk(PKSyncSettings(true, false, true, true, true, true), PKSyncAllSettings(true, true), pkUnitTestToken);
  });
}
