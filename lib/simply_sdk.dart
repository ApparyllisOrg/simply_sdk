library simply_sdk;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:simply_sdk/api/analytics.dart';
import 'package:simply_sdk/api/automatedTimers.dart';
import 'package:simply_sdk/api/chats.dart';
import 'package:simply_sdk/api/comments.dart';
import 'package:simply_sdk/api/customFronts.dart';
import 'package:simply_sdk/api/friends.dart';
import 'package:simply_sdk/api/frontHistory.dart';
import 'package:simply_sdk/api/groups.dart';
import 'package:simply_sdk/api/members.dart';
import 'package:simply_sdk/api/messages.dart';
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
import 'package:simply_sdk/modules/debug.dart';
import 'package:simply_sdk/modules/eventListener.dart';
import 'package:simply_sdk/modules/events.dart';
import 'package:simply_sdk/modules/socket.dart';
import 'package:simply_sdk/modules/store.dart';
import 'package:simply_sdk/modules/subscriptions.dart';

import 'api/tokens.dart';
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

    await _debug.init();
    await _cache.initialize("");
    _network.initialize();
    _socket.bindAuthChanged();

    await _events.load();
  }

  // Declare globals
  final Auth _auth = Auth();
  final Cache _cache = Cache();
  final Connection _connection = Connection();
  final Network _network = Network();
  final Socket _socket = Socket();
  final DocumentSubscriptions _documentSubscriptions = DocumentSubscriptions();
  final RemoteConfig _remoteConfig = RemoteConfig();
  final Debug _debug = Debug();
  final Event _events = Event();
  final EventListener _eventListener = EventListener();

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
  final Tokens _tokens = Tokens();
  final Analytics _analytics = Analytics();
  final Messages _messages = Messages();
  final ChannelCategories _channelCategories = ChannelCategories();
  final Channels _channels = Channels();

  // Declare global getters
  Auth auth() => _auth;
  Cache cache() => _cache;
  Connection connection() => _connection;
  Network network() => _network;
  Socket socket() => _socket;
  DocumentSubscriptions docSubscriptions() => _documentSubscriptions;
  RemoteConfig remoteConfig() => _remoteConfig;
  Debug debug() => _debug;
  Event event() => _events;
  EventListener eventListener() => _eventListener;

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
  Tokens tokens() => _tokens;
  Analytics analytics() => _analytics;
  Messages messages() => _messages;
  ChannelCategories channelCategories() => _channelCategories;
  Channels channels() => _channels;

  void reportError(e, StackTrace? trace) {
    try {
      if (onErrorReported != null) onErrorReported!(e, trace);
    } catch (e) {}
  }

  void Function(Object, StackTrace?)? onErrorReported;
}
