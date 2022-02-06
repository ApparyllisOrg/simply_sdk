import 'package:simply_sdk/api/customFronts.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/api/groups.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class Store {
  bool storeInitialized = false;

  List<Document<MemberData>> _members = [];
  List<Document<CustomFrontData>> _customFronts = [];
  List<Document<GroupData>> _groups = [];
  List<Document<FrontHistoryData>> _fronters = [];

  List<Document<MemberData>> getAllMembers() => _members;
  List<Document<CustomFrontData>> getAllCustomFronts() => _customFronts;
  List<Document<GroupData>> getAllGroups() => _groups;
  List<Document<FrontHistoryData>> getFronters() => _fronters;

  List<void Function(Document<FrontHistoryData>)> _frontChanges = [];
  List<Function?> _onInitialized = [];

  Future<void> initializeStore() async {
    clearStore();
    _members = await API().members().getAll();
    _customFronts = await API().customFronts().getAll();
    _groups = await API().groups().getAll();
    _fronters = await API().frontHistory().getCurrentFronters();

    // Emit initial changes
    if (_members.isNotEmpty) API().members().propogateChanges(_members.first, EChangeType.Update);
    if (_customFronts.isNotEmpty) API().customFronts().propogateChanges(_customFronts.first, EChangeType.Update);
    if (_groups.isNotEmpty) API().groups().propogateChanges(_groups.first, EChangeType.Update);
    if (_fronters.isNotEmpty) API().frontHistory().propogateChanges(_fronters.first, EChangeType.Update);

    API().members().listenForChanges(memberChanged);
    API().customFronts().listenForChanges(customFrontChanged);
    API().groups().listenForChanges(groupChanged);
    API().frontHistory().listenForChanges(frontHistoryChanged);

    storeInitialized = true;

    _onInitialized.forEach((element) {
      if (element != null) element();
    });
  }

  void clearStore() {
    storeInitialized = false;

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

  void frontHistoryChanged(Document<FrontHistoryData> data, EChangeType changeType) {
    int index = _fronters.indexWhere((element) => element.id == data.id);

    Document<FrontHistoryData>? previousFhDoc = index >= 0 ? _fronters[index] : null;

    // Create a new instance so that when "updateDocumentInList", we still have the original values
    // Also copy the data, because we need a deep copy but dart doesn't have deep copy so we need to manually do it
    if (previousFhDoc != null) {
      previousFhDoc = Document<FrontHistoryData>(true, previousFhDoc.id, FrontHistoryData.copyFrom(previousFhDoc.dataObject), previousFhDoc.type);
    }

    Document<FrontHistoryData> fhDoc = data;

    updateDocumentInList<FrontHistoryData>(_fronters, data, changeType);
    _fronters.removeWhere((element) => (element.dataObject.live ?? true) == false);

    if (previousFhDoc != null) {
      // If we're no longer a live fronter, notify of front change
      bool wasLive = (previousFhDoc.dataObject.live ?? false) == true;
      bool isLive = (fhDoc.dataObject.live ?? false) == true;

      if (wasLive && !isLive) {
        _notifyFrontChange(fhDoc);
      }

      // If was live and is live but member or time change, also notify of front changes
      if (wasLive && isLive) {
        if (fhDoc.dataObject.startTime != previousFhDoc.dataObject.startTime) {
          _notifyFrontChange(fhDoc);
        } else if (fhDoc.dataObject.member != previousFhDoc.dataObject.member) {
          _notifyFrontChange(fhDoc);
        }
      }
    } else if (previousFhDoc != null && (previousFhDoc.dataObject.live ?? false) == true) {
      _notifyFrontChange(fhDoc);
    } else if (previousFhDoc == null && data.dataObject.live == true) {
      _notifyFrontChange(fhDoc);
    }
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

  void listenForInitializeChanges(Function func) {
    _onInitialized.add(func);
  }

  void cancelListenForInitializeChanges(Function func) {
    _onInitialized.remove(func);
  }

  void _notifyFrontChange(Document<FrontHistoryData> doc) {
    _frontChanges.forEach((element) {
      element(doc);
    });
  }
}
