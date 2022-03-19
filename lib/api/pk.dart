import 'dart:convert';

import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/request.dart';

class PKSyncSettings {
  final bool syncName;
  final bool useDisplayName;
  final bool syncAvatar;
  final bool syncPronouns;
  final bool syncDesc;
  final bool syncColor;

  PKSyncSettings(this.syncName, this.useDisplayName, this.syncAvatar, this.syncPronouns, this.syncDesc, this.syncColor);
}

class PKSyncAllSettings {
  final bool override;
  final bool add;

  PKSyncAllSettings(this.override, this.add);
}

class PK {
  Future<RequestResponse> syncMemberToPk(String memberId, PKSyncSettings settings, String pkToken) async {
    var response = await SimplyHttpClient()
        .patch(Uri.parse(API().connection().getRequestUrl('v1/integrations/pluralkit/sync/member/$memberId', "direction=push")),
            body: jsonEncode({
              "member": memberId,
              "token": pkToken,
              "options": {
                "name": settings.syncName,
                "avatar": settings.syncAvatar,
                "pronouns": settings.syncPronouns,
                "description": settings.syncDesc,
                "useDisplayName": settings.useDisplayName,
                "color": settings.syncColor,
              }
            }))
        .catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      return createResponseObject(response);
    }
    return RequestResponse(false, response.body);
  }

  Future<RequestResponse> syncMemberFromPk(String memberId, PKSyncSettings settings, String pkToken) async {
    var response = await SimplyHttpClient()
        .patch(Uri.parse(API().connection().getRequestUrl('v1/integrations/pluralkit/sync/member/$memberId', "direction=pull")),
            body: jsonEncode({
              "member": memberId,
              "token": pkToken,
              "options": {
                "name": settings.syncName,
                "avatar": settings.syncAvatar,
                "pronouns": settings.syncPronouns,
                "description": settings.syncDesc,
                "useDisplayName": settings.useDisplayName,
                "color": settings.syncColor,
              }
            }))
        .catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      return createResponseObject(response);
    }
    return RequestResponse(false, response.body);
  }

  Future<RequestResponse> syncMembersToPk(PKSyncSettings settings, PKSyncAllSettings allSettings, String pkToken) async {
    var response = await SimplyHttpClient()
        .patch(Uri.parse(API().connection().getRequestUrl('v1/integrations/pluralkit/sync/members', "direction=push")),
            body: jsonEncode({
              "token": pkToken,
              "options": {
                "name": settings.syncName,
                "avatar": settings.syncAvatar,
                "pronouns": settings.syncPronouns,
                "description": settings.syncDesc,
                "useDisplayName": settings.useDisplayName,
                "color": settings.syncColor,
              },
              "syncOptions": {"add": allSettings.add, "overwrite": allSettings.override}
            }))
        .catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      return createResponseObject(response);
    }
    return RequestResponse(false, response.body);
  }

  Future<RequestResponse> syncMembersFromPk(PKSyncSettings settings, PKSyncAllSettings allSettings, String pkToken) async {
    var response = await SimplyHttpClient()
        .patch(Uri.parse(API().connection().getRequestUrl('v1/integrations/pluralkit/sync/members', "direction=pull")),
            body: jsonEncode({
              "token": pkToken,
              "options": {
                "name": settings.syncName,
                "avatar": settings.syncAvatar,
                "pronouns": settings.syncPronouns,
                "description": settings.syncDesc,
                "useDisplayName": settings.useDisplayName,
                "color": settings.syncColor,
              },
              "syncOptions": {"add": allSettings.add, "overwrite": allSettings.override}
            }))
        .catchError(((e) => generateFailedResponse(e)));
    if (response.statusCode == 200) {
      return createResponseObject(response);
    }
    return RequestResponse(false, response.body);
  }
}
