import 'package:flutter/material.dart';
import 'package:simply_sdk/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (builder, asyncs) => Container(),
      future: Future(() async {
        await API().initialize();

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
      }),
    );
  }
}
