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

  List<void Function(Document<FrontHistoryData>)> _frontChanges = [];

  Future<void> initializeStore() async {
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
    _frontChanges = [];

    API().members().cancelListenForChanges(memberChanged);
    API().customFronts().cancelListenForChanges(customFrontChanged);
    API().groups().cancelListenForChanges(groupChanged);
    API().frontHistory().cancelListenForChanges(frontHistoryChanged);
  }

  void memberChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<MemberData>(_members, data as Document<MemberData>, changeType);
  }

  void customFrontChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<CustomFrontData>(_customFronts, data as Document<CustomFrontData>, changeType);
  }

  void groupChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<GroupData>(_groups, data as Document<GroupData>, changeType);
  }

  void frontHistoryChanged(Document<dynamic> data, EChangeType changeType) {
    int index = _fronters.indexWhere((element) => element.id == data.id);
    bool found = index >= 0;

    Document<FrontHistoryData> fhDoc = data as Document<FrontHistoryData>;
    if (index >= 0) {
      // If we're no longer a live fronter, notify of front change
      bool wasLive = (_fronters[index].dataObject.live ?? false) == true;
      bool isLive = (fhDoc.dataObject.live ?? false) == true;

      if (wasLive && !isLive) {
        _notifyFrontChange(fhDoc);
      }

      // If was live and is live but member or time change, also notify of front changes
      if (wasLive && isLive) {
        if (fhDoc.dataObject.startTime != _fronters[index].dataObject.startTime) {
          _notifyFrontChange(fhDoc);
        } else if (fhDoc.dataObject.member != _fronters[index].dataObject.member) {
          _notifyFrontChange(fhDoc);
        }
      }
    } else if (found && (_fronters[index].dataObject.live ?? false) == true) {
      _notifyFrontChange(fhDoc);
    } else if (!found && data.dataObject.live == true) {
      _notifyFrontChange(fhDoc);
    }

    updateDocumentInList<FrontHistoryData>(_fronters, data, changeType);
    _fronters.removeWhere((element) => (element.dataObject.live ?? true) == false);
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

  void listenForFrontChanges(void Function(Document<FrontHistoryData>) func) {
    _frontChanges.add(func);
  }

  void cancelListenForFrontChanges(void Function(Document<FrontHistoryData>) func) {
    _frontChanges.remove(func);
  }

  void _notifyFrontChange(Document<FrontHistoryData> doc) {
    _frontChanges.forEach((element) {
      element(doc);
    });
  }
}
