library simply_sdk;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:simply_sdk/api/automatedTimers.dart';
import 'package:simply_sdk/api/being/medication.dart';
import 'package:simply_sdk/api/being/medicationLogs.dart';
import 'package:simply_sdk/api/being/symptomLogs.dart';
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
import 'package:simply_sdk/modules/pluralStore.dart';
import 'package:simply_sdk/modules/subscriptions.dart';

import 'api/being/symptoms.dart';
import 'api/tokens.dart';
import 'modules/beingStore.dart';
import 'modules/network.dart';

class APISettings {}

class API {
  static API? _instance;

  API._() {
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  factory API() {
    if (_instance == null) {
      _instance = new API._();
    }
    return _instance!;
  }

  Future<void> initialize({APISettings? settings}) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(details.exception, details.stack);
    };

    await _cache.initialize("");
    _network.initialize();
    _socket.bindAuthChanged();
  }

  // Declare globals
  final Auth _auth = Auth();
  final Cache _cache = Cache();
  final Connection _connection = Connection();
  final Network _network = Network();
  final Socket _socket = Socket();
  final DocumentSubscriptions _documentSubscriptions = DocumentSubscriptions();
  final RemoteConfig _remoteConfig = RemoteConfig();

  // Declare Simply Plural Api globals
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
  final PluralStore _pluralStore = PluralStore();
  final PK _pk = PK();
  final Tokens _tokens = Tokens();

  // Declare Simply Being Api globals
  final Symptoms _symptoms = Symptoms();
  final SymptomLogs _symptomLogs = SymptomLogs();
  final Medication _medication = Medication();
  final MedicationLogs _medicationLogs = MedicationLogs();
  final BeingStore _beingStore = BeingStore();

  // Declare global getters
  Auth auth() => _auth;
  Cache cache() => _cache;
  Connection connection() => _connection;
  Network network() => _network;
  Socket socket() => _socket;
  DocumentSubscriptions docSubscriptions() => _documentSubscriptions;
  RemoteConfig remoteConfig() => _remoteConfig;

  // Declare Simply Plural Api global getters
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
  PluralStore pluralStore() => _pluralStore;
  PK pk() => _pk;
  Tokens tokens() => _tokens;

  // Declare Simply Being Api global getters
  Symptoms symptoms() => _symptoms;
  SymptomLogs symptomLogs() => _symptomLogs;
  Medication medication() => _medication;
  MedicationLogs medicationLogs() => _medicationLogs;
  BeingStore beingStore() => _beingStore;

  void reportError(e, StackTrace? trace) {
    try {
      if (onErrorReported != null) onErrorReported!(e, trace);
    } catch (e) {}
  }

  void Function(Object, StackTrace?)? onErrorReported;
}
