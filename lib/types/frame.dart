import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';

class FrameData implements DocumentData {
  String? bgShape;
  String? bgClip;
  String? bgStartColor;
  String? bgEndColor;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = {};

    insertData('bgShape', bgShape, payload);
    insertData('bgClip', bgClip, payload);
    insertData('bgStartColor', bgStartColor, payload);
    insertData('bgEndColor', bgEndColor, payload);

    return payload;
  }

  @override
  void constructFromJson(Map<String, dynamic> json) {
    bgShape = readDataFromJson('bgShape', json);
    bgClip = readDataFromJson('bgClip', json);
    bgStartColor = readDataFromJson('bgStartColor', json);
    bgEndColor = readDataFromJson('bgEndColor', json);
  }

  void constructFromOptionalJson(Map<String, dynamic>? json) {
    if (json != null) {
      constructFromJson(json);
    }
  }
}
