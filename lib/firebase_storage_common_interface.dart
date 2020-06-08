// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library firebase_storage_common_interface;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/method_channel/method_channel_firebase_storage.dart';

// Shared types
export 'src/event.dart';
export 'src/storage_metadata.dart';
export 'src/storage_reference.dart';
export 'src/upload_task.dart';

/// Defines an interface to work with [FirebaseStoragePlatform] on web and mobile
abstract class FirebaseStoragePlatform extends PlatformInterface {
  /// The app associated with this Firestore instance.
  final FirebaseApp app;

  /// Create an instance using [app]
  FirebaseStoragePlatform({FirebaseApp app})
      : app = app ?? FirebaseApp.instance,
        super(token: _token);

  static final Object _token = Object();

  /// Create an instance using [app] using the existing implementation
  factory FirebaseStoragePlatform.instanceFor({FirebaseApp app}) {
    return FirebaseStoragePlatform.instance.withApp(app);
  }

  /// The current default [FirebaseStoragePlatform] instance.
  ///
  /// It will always default to [MethodChannelFirebaseStorage]
  /// if no web implementation was provided.
  static FirebaseStoragePlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelFirebaseStorage();
    }
    return _instance;
  }

  static FirebaseStoragePlatform _instance;

  get storageBucket => null;

  /// Sets the [FirebaseStoragePlatform.instance]
  static set instance(FirebaseStoragePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Create a new [FirebaseStoragePlatform] with a [FirebaseApp] instance
  FirebaseStoragePlatform withApp(FirebaseApp app) {
    throw UnimplementedError("withApp() not implemented");
  }

  /// Setup [FirebaseStoragePlatform] with settings.
  ///
  /// If [sslEnabled] has a non-null value, the [host] must have non-null value as well.
  ///
  /// If [cacheSizeBytes] is `null`, then default values are used.
  Future<void> settings(
      {bool persistenceEnabled,
      String host,
      bool sslEnabled,
      int cacheSizeBytes}) async {
    throw UnimplementedError('settings() is not implemented');
  }

  @override
  int get hashCode => app.name.hashCode;

  @override
  bool operator ==(dynamic o) => o is FirebaseStoragePlatform && o.app == app;
}
