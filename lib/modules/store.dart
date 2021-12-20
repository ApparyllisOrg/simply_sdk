import 'package:simply_sdk/api/customFronts.dart';
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

  List<Document<MemberData>> getAllMembers() => _members;
  List<Document<CustomFrontData>> getAllCustomFronts() => _customFronts;
  List<Document<GroupData>> getAllGroups() => _groups;

  void initializeStore() async
  {
    clearStore();
    _members = await API().members().getAll();
    _customFronts = await API().customFronts().getAll();
    _groups = await API().groups().getAll();

    API().members().listenForChanges(memberChanged);
    API().customFronts().listenForChanges(memberChanged);
    API().groups().listenForChanges(memberChanged);
  }

  void clearStore()
  {
    _members = [];
    _customFronts = [];
    _groups = [];

    API().members().cancelListenForChanges(memberChanged);
    API().customFronts().cancelListenForChanges(memberChanged);
    API().groups().cancelListenForChanges(memberChanged);
  }

  void memberChanged(Document<dynamic> data, EChangeType changeType)
  {
    updateDocumentInList(_members, data, changeType);
  }

  void customFrontChanged(Document<dynamic> data, EChangeType changeType)
  {
    updateDocumentInList(_customFronts, data, changeType);
  }

  void groupChanged(Document<dynamic> data, EChangeType changeType)
  {
    updateDocumentInList(_groups, data, changeType);
  }
}
