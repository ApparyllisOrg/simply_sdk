import 'package:http/http.dart';
import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/widgets/paginate.dart';
import 'package:test/test.dart';


void runTests(userId) {
  test('get first page', () async {
    Response response = await PaginateState.getNextPage('v1/frontHistory', 'startTime', -1, 10, 0);
    if (response.statusCode != 200) {
      print(response.body);
    }
    expect(response.statusCode, 200);

    expect(convertServerResponseToList(response).length, 10);
  });

  test('get second page', () async {
    Response response = await PaginateState.getNextPage('v1/frontHistory', 'startTime', -1, 10, 10);
    if (response.statusCode != 200) {
      print(response.body);
    }
    expect(response.statusCode, 200);

    expect(convertServerResponseToList(response).length, 10);
  });
}
