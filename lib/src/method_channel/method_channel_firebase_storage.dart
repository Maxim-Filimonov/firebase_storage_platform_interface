import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../../firebase_storage_common_interface.dart';

class MethodChannelFirebaseStorage extends FirebaseStoragePlatform {
  /// Used to dispatch method calls
  static final StreamController<MethodCall> _methodStreamController =
      StreamController<MethodCall>.broadcast(); // ignore: close_sinks
  static Stream<MethodCall> get methodStream => _methodStreamController.stream;

  /// Create an instance of [MethodChannelFirebaseStorage] with optional [FirebaseApp]
  MethodChannelFirebaseStorage({FirebaseApp app})
      : super(app: app ?? FirebaseApp.instance) {
    if (_initialized) return;
    channel.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
    });
    // channel.setMethodCallHandler((MethodCall call) async {
    //   if (call.method == 'QuerySnapshot') {
    //     final QuerySnapshotPlatform snapshot =
    //         MethodChannelQuerySnapshot(call.arguments, this);
    //     queryObservers[call.arguments['handle']].add(snapshot);
    //   } else if (call.method == 'DocumentSnapshot') {
    //     final DocumentSnapshotPlatform snapshot = DocumentSnapshotPlatform(
    //       call.arguments['path'],
    //       asStringKeyedMap(call.arguments['data']),
    //       SnapshotMetadataPlatform(
    //           call.arguments['metadata']['hasPendingWrites'],
    //           call.arguments['metadata']['isFromCache']),
    //       this,
    //     );
    //     documentObservers[call.arguments['handle']].add(snapshot);
    //   } else if (call.method == 'DoTransaction') {
    //     final int transactionId = call.arguments['transactionId'];
    //     final TransactionPlatform transaction =
    //         MethodChannelTransaction(transactionId, call.arguments["app"]);
    //     final dynamic result =
    //         await _transactionHandlers[transactionId](transaction);
    //     await transaction.finish();
    //     return result;
    //   }
    // });
    _initialized = true;
  }

  /// The [FirebaseApp] instance to which this [FirebaseDatabase] belongs.
  ///
  /// If null, the default [FirebaseApp] is used.

  static bool _initialized = false;

  /// The [MethodChannel] used to communicate with the native plugin
  static MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_storage');

  @override
  FirebaseStoragePlatform withApp(FirebaseApp app) =>
      MethodChannelFirebaseStorage(app: app);
}
