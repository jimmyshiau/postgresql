library postgresql.pool;

import 'dart:async';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:postgresql/src/pool_impl_cps.dart';
import 'package:postgresql/src/pool_settings_impl.dart';

//TODO docs
abstract class Pool {
  
  factory Pool(String databaseUri,
    {String poolName,
    int minConnections,
    int maxConnections,
    Duration startTimeout,
    Duration stopTimeout,
    Duration establishTimeout,
    Duration connectionTimeout,
    Duration idleTimeout,
    Duration maxLifetime,
    Duration leakDetectionThreshold,
    bool testConnections,
    bool restartIfAllConnectionsLeaked,
    pg.TypeConverter typeConverter})
      
      => new PoolImpl(new PoolSettingsImpl.withDefaults(
              databaseUri: databaseUri,
              poolName: poolName,
              minConnections: minConnections,
              maxConnections: maxConnections,
              startTimeout: startTimeout,
              stopTimeout: stopTimeout,
              establishTimeout: establishTimeout,
              connectionTimeout: connectionTimeout,
              idleTimeout: idleTimeout,
              maxLifetime: maxLifetime,
              leakDetectionThreshold: leakDetectionThreshold,
              testConnections: testConnections,
              restartIfAllConnectionsLeaked: restartIfAllConnectionsLeaked),
            typeConverter);
  
  factory Pool.fromSettings(PoolSettings settings, {pg.TypeConverter typeConverter})
    => new PoolImpl(settings, typeConverter);
  
  Future start();
  Future stop();
  Future<pg.Connection> connect({String debugId});
  PoolState get state;
  Stream<pg.Message> get messages;
  List<PooledConnection> get connections;
  int get waitQueueLength;
}


//FIXME docs
abstract class PoolSettings {

  factory PoolSettings({
      String databaseUri,
      String poolName,
      int minConnections,
      int maxConnections,
      Duration startTimeout,
      Duration stopTimeout,
      Duration establishTimeout,
      Duration connectionTimeout,
      Duration idleTimeout,
      Duration maxLifetime,
      Duration leakDetectionThreshold,
      bool testConnections,
      bool restartIfAllConnectionsLeaked}) = PoolSettingsImpl;
  
  factory PoolSettings.fromMap(Map map) = PoolSettingsImpl.fromMap;

  String get databaseUri;
  String get poolName;
  int get minConnections;
  int get maxConnections;
  Duration get startTimeout;
  Duration get stopTimeout;
  Duration get establishTimeout; //TODO better name
  Duration get connectionTimeout; //TODO better name
  
  /// Also has random 20s added.
  Duration get idleTimeout;
  
  /// Note max lifetime has a random ammount of seconds added between 0 and 20.
  /// This to stagger the expiration, so all connections don't get restarted at
  /// at the same time after the pool has started and maxLifetime is reached.
  Duration get maxLifetime;
  Duration get leakDetectionThreshold;
  bool get testConnections;
  bool get restartIfAllConnectionsLeaked;
  
  Map toMap();
  Map toJson();
}

//TODO change to enum once implemented.
class PoolState {
  const PoolState(this.name);
  final String name;
  toString() => name;

  static const PoolState initial = const PoolState('inital');
  static const PoolState starting = const PoolState('starting');
  static const PoolState running = const PoolState('running');
  static const PoolState stopping = const PoolState('stopping');
  static const PoolState stopped = const PoolState('stopped');
}

abstract class PooledConnection {
  
  /// The state of connection in the pool, available, closed
  PooledConnectionState get state;

  /// Time at which the physical connection to the database was established.
  DateTime get established;

  /// Time at which the connection was last obtained by a client.
  DateTime get obtained;

  /// Time at which the connection was last released by a client.
  DateTime get released;
  
  /// The pid of the postgresql handler.
  int get backendPid;

  /// The id passed to connect for debugging.
  String get debugId;

  /// A unique id that updated whenever the connection is obtained.
  int get useId;
  
  /// If a leak detection threshold is set, then this flag will be set on leaked
  /// connections.
  bool get isLeaked;

  /// The stacktrace at the time pool.connect() was last called.
  StackTrace get stackTrace;
  
  pg.ConnectionState get connectionState;
  
  String get name;
}


//TODO change to enum once implemented.
class PooledConnectionState {
  const PooledConnectionState(this.name);
  final String name;
  toString() => name;

  static const PooledConnectionState connecting = const PooledConnectionState('connecting');  
  static const PooledConnectionState available = const PooledConnectionState('available');
  static const PooledConnectionState reserved = const PooledConnectionState('reserved');
  static const PooledConnectionState testing = const PooledConnectionState('testing');
  static const PooledConnectionState inUse = const PooledConnectionState('inUse');
  static const PooledConnectionState closed = const PooledConnectionState('closed');
}
