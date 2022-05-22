import 'dart:convert';

import 'package:simply_sdk/helpers.dart';
import 'package:simply_sdk/modules/collection.dart';

import '../modules/http.dart';
import '../simply_sdk.dart';

class AnalyticsValueData implements DocumentData {
  String? id;
  double? value;

  @override
  constructFromJson(Map<String, dynamic> json) {
    id = readDataFromJson("id", json);
    value = readDataFromJson("value", json);
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class AnalyticsTimingsData implements DocumentData {
  List<AnalyticsValueData>? morningFronters;
  List<AnalyticsValueData>? dayFronters;
  List<AnalyticsValueData>? eveningFronters;
  List<AnalyticsValueData>? nightFronters;

  @override
  constructFromJson(Map<String, dynamic> json) {
    morningFronters = readDataTypeArrayFromJson<AnalyticsValueData>(
        "morningFronters",
        json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
    dayFronters = readDataTypeArrayFromJson<AnalyticsValueData>("dayFronters",
        json, ((data) => AnalyticsValueData()..constructFromJson(data)));
    eveningFronters = readDataTypeArrayFromJson<AnalyticsValueData>(
        "eveningFronters",
        json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
    nightFronters = readDataTypeArrayFromJson<AnalyticsValueData>(
        "nightFronters",
        json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class AnalyticsDurationsData implements DocumentData {
  List<AnalyticsValueData>? sums;
  List<AnalyticsValueData>? averages;
  List<AnalyticsValueData>? maxes;
  List<AnalyticsValueData>? mins;

  @override
  constructFromJson(Map<String, dynamic> json) {
    sums = readDataTypeArrayFromJson<AnalyticsValueData>("sums", json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
    averages = readDataTypeArrayFromJson<AnalyticsValueData>("averages", json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
    maxes = readDataTypeArrayFromJson<AnalyticsValueData>("maxes", json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
    mins = readDataTypeArrayFromJson<AnalyticsValueData>("mins", json,
        ((data) => AnalyticsValueData()..constructFromJson(data)));
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class AnalyticsData implements DocumentData {
  AnalyticsTimingsData? timigs;
  AnalyticsDurationsData? values;

  @override
  constructFromJson(Map<String, dynamic> json) {
    if (json["timings"] != null) {
      timigs = AnalyticsTimingsData()
        ..constructFromJson(json["timings"] as Map<String, dynamic>);
    }

    if (json["values"] != null) {
      values = AnalyticsDurationsData()
        ..constructFromJson(json["values"] as Map<String, dynamic>);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class Analytics {
  Future<AnalyticsData?> get() {
    return Future(() async {
      var response = await SimplyHttpClient()
          .get(Uri.parse(
              API().connection().getRequestUrl('v1/user/analytics', "")))
          .catchError(((e) => generateFailedResponse(e)));

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AnalyticsData()
          ..constructFromJson(jsonResponse as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }
}
