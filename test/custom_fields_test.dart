import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/users.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';


void runTests(userId) {
  test('get custom fields', () async {
    Document<UserData> user = await API().users().get(API().auth().getUid() ?? '');
    expect(user.dataObject.fields != null, true);

    user.dataObject.fields!.forEach((key, value) {
      print(value.toJson());
    });
  });
}
