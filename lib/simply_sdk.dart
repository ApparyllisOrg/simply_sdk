library simply_sdk;

import 'package:simply_sdk/api/automatedTimers.dart';
import 'package:simply_sdk/api/comments.dart';
import 'package:simply_sdk/api/customFronts.dart';
import 'package:simply_sdk/api/friends.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/api/groups.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/api/notes.dart';
import 'package:simply_sdk/api/pk.dart';
import 'package:simply_sdk/api/polls.dart';
import 'package:simply_sdk/api/privates.dart';
import 'package:simply_sdk/api/repeatedTimers.dart';
import 'package:simply_sdk/api/storage.dart';
import 'package:simply_sdk/api/users.dart';
import 'package:simply_sdk/modules/auth.dart';
import 'package:simply_sdk/modules/cache.dart';
import 'package:simply_sdk/modules/config.dart';
import 'package:simply_sdk/modules/connection.dart';
import 'package:simply_sdk/modules/socket.dart';
import 'package:simply_sdk/modules/store.dart';
import 'package:simply_sdk/modules/subscriptions.dart';

import 'modules/network.dart';

class APISettings {}

class API {
  static final API _instance = API();
  factory API() => _instance;

  Future<void> initialize({APISettings? settings}) async {
    _auth = Auth();
    _cache = Cache();
    _connection = Connection();
    _socket = Socket();
    _network = Network();
    _documentSubscriptions = DocumentSubscriptions();
    _remoteConfig = RemoteConfig();
    await _cache.initialize("");
  }

  // Declare globals
  late Auth _auth;
  late Cache _cache;
  late Connection _connection;
  late Network _network;
  late Socket _socket;
  late DocumentSubscriptions _documentSubscriptions;
  late RemoteConfig _remoteConfig;

  // Declare Api globals
  final AutomatedTimers _automatedTimers = AutomatedTimers();
  final Comments _comments = Comments();
  final CustomFronts _customFronts = CustomFronts();
  final Friends _friends = Friends();
  final FrontHistory _frontHistory = FrontHistory();
  final Groups _groups = Groups();
  final Members _members = Members();
  final Notes _notes = Notes();
  final Polls _polls = Polls();
  final Privates _privates = Privates();
  final RepeatedTimers _repeatedTimers = RepeatedTimers();
  final Storage _storage = Storage();
  final Users _users = Users();
  final Store _store = Store();
  final PK _pk = PK();

  // Declare global getters
  Auth auth() => _auth;
  Cache cache() => _cache;
  Connection connection() => _connection;
  Network network() => _network;
  Socket socket() => _socket;
  DocumentSubscriptions docSubscriptions() => _documentSubscriptions;
  RemoteConfig remoteConfig() => _remoteConfig;

  // Declare Api global getters
  AutomatedTimers automatedTimers() => _automatedTimers;
  Comments comments() => _comments;
  CustomFronts customFronts() => _customFronts;
  Friends friends() => _friends;
  FrontHistory frontHistory() => _frontHistory;
  Groups groups() => _groups;
  Members members() => _members;
  Notes notes() => _notes;
  Polls polls() => _polls;
  Privates privates() => _privates;
  RepeatedTimers repeatedTimers() => _repeatedTimers;
  Storage storage() => _storage;
  Users users() => _users;
  Store store() => _store;
  PK pk() => _pk;

  void reportError(e, StackTrace trace) {
    try {
      onErrorReported!(e, trace);
    } catch (e) {}
  }

  Function? onErrorReported;
}
