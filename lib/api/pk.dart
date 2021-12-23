import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/types/request.dart';

class PKSyncSettings {
  final bool syncName;
  final bool useDisplayName;
  final bool syncAvatar;
  final bool syncPronouns;
  final bool syncDesc;
  final bool syncColor;

  PKSyncSettings(this.syncName, this.useDisplayName, this.syncAvatar,
      this.syncPronouns, this.syncDesc, this.syncColor);
}

class PKSyncAllSettings {
  final bool override;
  final bool add;

  PKSyncAllSettings(this.override, this.add);
}

class PK {
  Future<RequestResponse> syncMemberToPk(
      String memberId, PKSyncSettings settings, String pkToken) async {
    var response = await SimplyHttpClient().patch(Uri.parse(
        'v1/integrations/pluralkit/sync/member/$memberId?direction=push'),
        body: {
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
        });
    if (response.statusCode == 200) {
      return RequestResponse(true, "");
    }
     return RequestResponse(false, response.body);
  }

  Future<RequestResponse> syncMemberFromPk(
      String memberId, PKSyncSettings settings, String pkToken) async {
    var response = await SimplyHttpClient().patch(Uri.parse(
        'v1/integrations/pluralkit/sync/member/$memberId?direction=pull'),
        body: {
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
        });
    if (response.statusCode == 200) {
      return RequestResponse(true, "");
    }
     return RequestResponse(false, response.body);
  }

  Future<RequestResponse> syncMembersToPk(
      String memberId, PKSyncSettings settings, PKSyncAllSettings allSettings, String pkToken) async {
    var response = await SimplyHttpClient().patch(Uri.parse(
        'v1/integrations/pluralkit/sync/members?direction=push'),
        body: {
          "member": memberId,
          "token": pkToken,
          "options": {
            "name": settings.syncName,
            "avatar": settings.syncAvatar,
            "pronouns": settings.syncPronouns,
            "description": settings.syncDesc,
            "useDisplayName": settings.useDisplayName,
            "color": settings.syncColor,
          },
          "syncOptions":{
            "add": allSettings.add,
            "override": allSettings.override
          }
        });
    if (response.statusCode == 200) {
      return RequestResponse(true, "");
    }
     return RequestResponse(false, response.body);
  }

  Future<RequestResponse> syncMembersFromPk(
      String memberId, PKSyncSettings settings, PKSyncAllSettings allSettings, String pkToken) async {
    var response = await SimplyHttpClient().patch(Uri.parse(
        'v1/integrations/pluralkit/sync/members?direction=pull'),
        body: {
          "member": memberId,
          "token": pkToken,
          "options": {
            "name": settings.syncName,
            "avatar": settings.syncAvatar,
            "pronouns": settings.syncPronouns,
            "description": settings.syncDesc,
            "useDisplayName": settings.useDisplayName,
            "color": settings.syncColor,
          },
          "syncOptions": {
            "add": allSettings.add,
            "override": allSettings.override
          }
        });
    if (response.statusCode == 200) {
      return RequestResponse(true, "");
    }
     return RequestResponse(false, response.body);
  }
}
