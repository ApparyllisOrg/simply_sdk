import 'dart:convert';

import 'package:http/http.dart';
import 'package:simply_sdk/api/chats.dart';
import 'package:simply_sdk/api/customFields.dart';
import 'package:simply_sdk/api/customFronts.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/api/groups.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

class Store {
  bool storeInitialized = false;

  List<Document<MemberData>> _members = [];
  List<Document<CustomFrontData>> _customFronts = [];
  List<Document<GroupData>> _groups = [];
  List<Document<FrontHistoryData>> _fronters = [];
  List<Document<ChannelData>> _channels = [];

  List<Document<MemberData>> getAllMembers() => _members;
  List<Document<CustomFrontData>> getAllCustomFronts() => _customFronts;
  List<Document<GroupData>> getAllGroups() => _groups;
  List<Document<FrontHistoryData>> getFronters() => _fronters;
  List<Document<ChannelData>> getChannels() => _channels;

  List<void Function(Document<FrontHistoryData>, bool)> _frontChanges = [];
  final List<Function?> _onInitialized = [];

  Future<void> fetchStartupValues(bool bForceOffline) async {
    if (!API().auth().canSendHttpRequests()) {
      await API().auth().waitForAbilityToSendRequests();
    }

    bool fetchCache = bForceOffline;

    if (!bForceOffline) {
      final Response response = await SimplyHttpClient()
          .get(Uri.parse(API().connection().getRequestUrl('v1/startup', '')))
          .timeout(const Duration(seconds: 10))
          .catchError((e) => generateFailedResponse(e));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body) as Map<String, dynamic>;

        _members = _initializeDataType(result, 'members', (data) => MemberData()..constructFromJson(data));
        _customFronts = _initializeDataType(result, 'customFronts', (data) => CustomFrontData()..constructFromJson(data), overrideLocalType: 'FrontStatuses');
        _groups = _initializeDataType(result, 'groups', (data) => GroupData()..constructFromJson(data));
        _fronters = _initializeDataType(result, 'fronters', (data) => FrontHistoryData()..constructFromJson(data));
        _channels = _initializeDataType(result, 'channels', (data) => ChannelData()..constructFromJson(data));

        API().cache().cacheListOfDocuments(_members);
        API().cache().cacheListOfDocuments(_customFronts);
        API().cache().cacheListOfDocuments(_groups);
        API().cache().cacheListOfDocuments(_fronters);
        API().cache().cacheListOfDocuments(_channels);
      } else {
        fetchCache = true;
      }
    }

    if (fetchCache) {
      _members = API().cache().getDocuments('Members', (data) => MemberData()..constructFromJson(data));
      _customFronts = API().cache().getDocuments('FrontStatuses', (data) => CustomFrontData()..constructFromJson(data));
      _groups = API().cache().getDocuments('Groups', (data) => GroupData()..constructFromJson(data));
      _fronters = API().cache().getDocumentsWhere<FrontHistoryData>(
          'FrontHistory', (doc) => doc.dataObject.live ?? false, (data) => FrontHistoryData()..constructFromJson(data));
      _channels = API().cache().getDocuments('Members', (data) => ChannelData()..constructFromJson(data));
    }
  }

  List<Document<T>> _initializeDataType<T>(final Map<String, dynamic> data, String type, T Function(Map<String, dynamic> json) constructFromJson, { String? overrideLocalType } ) {
    final List<dynamic> contentList = data[type] as List<dynamic>;
    final List<Map<String, dynamic>> contentListValues = contentList.map((e) => e as Map<String, dynamic>).toList();

    return contentListValues.map<Document<T>>((e) => Document(e['exists'], e['id'], constructFromJson(e['content']), overrideLocalType ?? type)).toList();
  }

  Future<void> initializeStore({bool bForceOffline = false}) async {
    clearStore();

    await fetchStartupValues(bForceOffline);

    // Emit initial changes
    if (_members.isNotEmpty) API().members().propogateChanges(_members.first, EChangeType.Update, false);
    if (_customFronts.isNotEmpty) API().customFronts().propogateChanges(_customFronts.first, EChangeType.Update, false);
    if (_groups.isNotEmpty) API().groups().propogateChanges(_groups.first, EChangeType.Update, false);
    if (_fronters.isNotEmpty) API().frontHistory().propogateChanges(_fronters.first, EChangeType.Update, false);
    if (_channels.isNotEmpty) API().channels().propogateChanges(_channels.first, EChangeType.Update, false);

    API().members().listenForChanges(memberChanged);
    API().customFronts().listenForChanges(customFrontChanged);
    API().groups().listenForChanges(groupChanged);
    API().frontHistory().listenForChanges(frontHistoryChanged);
    API().channels().listenForChanges(channelChanged);

    storeInitialized = true;

    _onInitialized.forEach((element) {
      if (element != null) element();
    });
  }

  // Edit this so that in the future we can use "since", in a way that takes in account deletions since
  Future<void> updateStore(int since) async {
    await fetchStartupValues(false);

    _fronters.forEach((element) {
      _notifyFrontChange(element, false);
    });
  }

  void clearStore() {
    storeInitialized = false;

    _members = [];
    _customFronts = [];
    _groups = [];
    _frontChanges = [];
    _channels = [];

    API().members().cancelListenForChanges(memberChanged);
    API().customFronts().cancelListenForChanges(customFrontChanged);
    API().groups().cancelListenForChanges(groupChanged);
    API().frontHistory().cancelListenForChanges(frontHistoryChanged);
    API().channels().cancelListenForChanges(channelChanged);
  }

  void memberChanged(Document<dynamic> data, EChangeType changeType, bool bLocalEvent) {
    updateDocumentInList<MemberData>(_members, data as Document<MemberData>, changeType);
  }

  void customFrontChanged(Document<dynamic> data, EChangeType changeType, bool bLocalEvent) {
    updateDocumentInList<CustomFrontData>(_customFronts, data as Document<CustomFrontData>, changeType);
  }

  void groupChanged(Document<dynamic> data, EChangeType changeType, bool bLocalEvent) {
    updateDocumentInList<GroupData>(_groups, data as Document<GroupData>, changeType);
  }

  void frontHistoryChanged(Document<FrontHistoryData> data, EChangeType changeType, bool bLocalEvent) {
    final int index = _fronters.indexWhere((element) => element.id == data.id);

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
      final bool wasLive = (previousFhDoc.dataObject.live ?? false) == true;
      final bool isLive = (fhDoc.dataObject.live ?? false) == true;

      if (wasLive && !isLive) {
        _notifyFrontChange(fhDoc, bLocalEvent);
      }

      // If was live and is live but member or time change, also notify of front changes
      if (wasLive && isLive) {
        if (fhDoc.dataObject.startTime != previousFhDoc.dataObject.startTime) {
          _notifyFrontChange(fhDoc, bLocalEvent);
        } else if (fhDoc.dataObject.member != previousFhDoc.dataObject.member) {
          _notifyFrontChange(fhDoc, bLocalEvent);
        }
      }
    } else if (previousFhDoc != null && (previousFhDoc.dataObject.live ?? false) == true) {
      _notifyFrontChange(fhDoc, bLocalEvent);
    } else if (previousFhDoc == null && data.dataObject.live == true) {
      _notifyFrontChange(fhDoc, bLocalEvent);
    }
  }

  void channelChanged(Document<dynamic> data, EChangeType changeType, bool bLocalEvent) {
    updateDocumentInList<ChannelData>(_channels, data as Document<ChannelData>, changeType);
  }

  bool isFronting(String id) => _fronters.indexWhere((element) => element.dataObject.member == id) != -1;

  bool isDocumentAMemberDocument(String id) {
    if (_members.any((element) => element.id == id)) {
      return true;
    }
    return false;
  }

  Document<MemberData>? getMemberById(String id) {
    final int index = _members.indexWhere((element) => element.id == id);
    if (index >= 0) return _members[index];
    return null;
  }

  Document<CustomFrontData>? getCustomFrontById(String id) {
    final int index = _customFronts.indexWhere((element) => element.id == id);
    if (index >= 0) return _customFronts[index];
    return null;
  }

  Document<GroupData>? getGroupById(String id) {
    final int index = _groups.indexWhere((element) => element.id == id);
    if (index >= 0) return _groups[index];
    return null;
  }

  Document<ChannelData>? getChannelById(String id) {
    final int index = _channels.indexWhere((element) => element.id == id);
    if (index >= 0) return _channels[index];
    return null;
  }

  bool isDocumentFronting(String id) {
    final int index = _fronters.indexWhere((element) => element.id == id);
    if (index >= 0) return true;
    return false;
  }

  Document<FrontHistoryData>? getFronterById(String id) {
    final int index = _fronters.indexWhere((element) => element.dataObject.member == id);
    if (index >= 0) return _fronters[index];
    return null;
  }

  void listenForFrontChanges(
    void Function(Document<FrontHistoryData>, bool) func,
  ) {
    _frontChanges.add(func);
  }

  void cancelListenForFrontChanges(void Function(Document<FrontHistoryData>, bool) func) {
    _frontChanges.remove(func);
  }

  void listenForInitializeChanges(Function func) {
    _onInitialized.add(func);
  }

  void cancelListenForInitializeChanges(Function func) {
    _onInitialized.remove(func);
  }

  void _notifyFrontChange(Document<FrontHistoryData> doc, bool bLocalEvent) {
    _frontChanges.forEach((element) {
      element(doc, bLocalEvent);
    });
  }
}
