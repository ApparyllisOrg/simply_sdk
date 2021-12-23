import 'package:simply_sdk/api/customFronts.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/api/groups.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class Store {
  List<Document<MemberData>> _members = [];
  List<Document<CustomFrontData>> _customFronts = [];
  List<Document<GroupData>> _groups = [];
  List<Document<FrontHistoryData>> _fronters = [];

  List<Document<MemberData>> getAllMembers() => _members;
  List<Document<CustomFrontData>> getAllCustomFronts() => _customFronts;
  List<Document<GroupData>> getAllGroups() => _groups;
  List<Document<FrontHistoryData>> getFronters() => _fronters;

  void initializeStore() async {
    clearStore();
    _members = await API().members().getAll();
    _customFronts = await API().customFronts().getAll();
    _groups = await API().groups().getAll();
    _fronters = await API().frontHistory().getCurrentFronters();

    API().members().listenForChanges(memberChanged);
    API().customFronts().listenForChanges(customFrontChanged);
    API().groups().listenForChanges(groupChanged);
    API().frontHistory().listenForChanges(frontHistoryChanged);
  }

  void clearStore() {
    _members = [];
    _customFronts = [];
    _groups = [];

    API().members().cancelListenForChanges(memberChanged);
    API().customFronts().cancelListenForChanges(customFrontChanged);
    API().groups().cancelListenForChanges(groupChanged);
    API().frontHistory().cancelListenForChanges(frontHistoryChanged);
  }

  void memberChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList(_members, data, changeType);
  }

  void customFrontChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList(_customFronts, data, changeType);
  }

  void groupChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList(_groups, data, changeType);
  }

  void frontHistoryChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList(_fronters, data, changeType);
    _fronters
        .removeWhere((element) => (element.dataObject.live ?? true) == false);
  }

  bool isDocumentAMemberDocument(String id) {
    if (_members.any((element) => element.id == id)) {
      return true;
    }
    return false;
  }

  Document<MemberData>? getMemberById(String id) {
    int index = _members.indexWhere((element) => element.id == id);
    if (index >= 0) return _members[index];
    return null;
  }

  Document<CustomFrontData>? getCustomFrontById(String id) {
    int index = _customFronts.indexWhere((element) => element.id == id);
    if (index >= 0) return _customFronts[index];
    return null;
  }

  Document<GroupData>? getGroupById(String id) {
    int index = _groups.indexWhere((element) => element.id == id);
    if (index >= 0) return _groups[index];
    return null;
  }

  bool isDocumentFronting(String id) {
    int index = _fronters.indexWhere((element) => element.id == id);
    if (index >= 0) return true;
    return false;
  }

  Document<FrontHistoryData>? getFronterById(String id) {
    int index = _fronters.indexWhere((element) => element.dataObject.member == id);
    if (index >= 0) return _fronters[index];
    return null;
  }
}
