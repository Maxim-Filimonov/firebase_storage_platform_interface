// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_firebase_storage.dart';
import 'package:flutter/services.dart';

import '../firebase_storage_common_interface.dart';
import 'error.dart';
import 'event.dart';
import 'platform_interface/file.dart';
import 'storage_metadata.dart';

abstract class StorageUploadTask {
  StorageUploadTask._(this._firebaseStorage, this._ref, this._metadata);

  final FirebaseStoragePlatform _firebaseStorage;
  final StorageReference _ref;
  final StorageMetadata _metadata;

  Future<dynamic> _platformStart();

  int _handle;

  bool isCanceled = false;
  bool isComplete = false;
  bool isInProgress = true;
  bool isPaused = false;
  bool isSuccessful = false;

  StorageTaskSnapshot lastSnapshot;

  /// Returns a last snapshot when completed
  Completer<StorageTaskSnapshot> _completer = Completer<StorageTaskSnapshot>();
  Future<StorageTaskSnapshot> get onComplete => _completer.future;

  StreamController<StorageTaskEvent> _controller =
      StreamController<StorageTaskEvent>.broadcast();
  Stream<StorageTaskEvent> get events => _controller.stream;

  Future<StorageTaskSnapshot> start() async {
    _handle = await _platformStart();
    final StorageTaskEvent event =
        await MethodChannelFirebaseStorage.methodStream.where((MethodCall m) {
      return m.method == 'StorageTaskEvent' && m.arguments['handle'] == _handle;
    }).map<StorageTaskEvent>((MethodCall m) {
      final Map<dynamic, dynamic> args = m.arguments;
      final StorageTaskEvent e =
          StorageTaskEvent(args['type'], _ref, args['snapshot']);
      _changeState(e);
      lastSnapshot = e.snapshot;
      _controller.add(e);
      if (e.type == StorageTaskEventType.success ||
          e.type == StorageTaskEventType.failure) {
        _completer.complete(e.snapshot);
      }
      return e;
    }).firstWhere((StorageTaskEvent e) =>
            e.type == StorageTaskEventType.success ||
            e.type == StorageTaskEventType.failure);
    return event.snapshot;
  }

  void _changeState(StorageTaskEvent event) {
    _resetState();
    switch (event.type) {
      case StorageTaskEventType.progress:
        isInProgress = true;
        break;
      case StorageTaskEventType.resume:
        isInProgress = true;
        break;
      case StorageTaskEventType.pause:
        isPaused = true;
        break;
      case StorageTaskEventType.success:
        isSuccessful = true;
        isComplete = true;
        break;
      case StorageTaskEventType.failure:
        isComplete = true;
        if (event.snapshot.error == StorageError.canceled) {
          isCanceled = true;
        }
        break;
    }
  }

  void _resetState() {
    isCanceled = false;
    isComplete = false;
    isInProgress = false;
    isPaused = false;
    isSuccessful = false;
  }

  /// Pause the upload
  void pause() => MethodChannelFirebaseStorage.channel.invokeMethod<void>(
        'UploadTask#pause',
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'handle': _handle,
        },
      );

  /// Resume the upload
  void resume() => MethodChannelFirebaseStorage.channel.invokeMethod<void>(
        'UploadTask#resume',
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'handle': _handle,
        },
      );

  /// Cancel the upload
  void cancel() => MethodChannelFirebaseStorage.channel.invokeMethod<void>(
        'UploadTask#cancel',
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'handle': _handle,
        },
      );
}

class StorageFileUploadTask extends StorageUploadTask {
  StorageFileUploadTask(this._file, FirebaseStoragePlatform firebaseStorage,
      StorageReference ref, StorageMetadata metadata)
      : super._(firebaseStorage, ref, metadata);

  final File _file;

  @override
  Future<dynamic> _platformStart() {
    return MethodChannelFirebaseStorage.channel.invokeMethod<dynamic>(
      'StorageReference#putFile',
      <String, dynamic>{
        'app': _firebaseStorage.app?.name,
        'bucket': _firebaseStorage.storageBucket,
        'filename': _file.filename,
        'path': _ref.path,
        'metadata':
            _metadata == null ? null : buildMetadataUploadMap(_metadata),
      },
    );
  }
}

class StorageDataUploadTask extends StorageUploadTask {
  StorageDataUploadTask(this._bytes, FirebaseStoragePlatform firebaseStorage,
      StorageReference ref, StorageMetadata metadata)
      : super._(firebaseStorage, ref, metadata);

  final Uint8List _bytes;

  @override
  Future<dynamic> _platformStart() {
    return MethodChannelFirebaseStorage.channel.invokeMethod<dynamic>(
      'StorageReference#putData',
      <String, dynamic>{
        'app': _firebaseStorage.app?.name,
        'bucket': _firebaseStorage.storageBucket,
        'data': _bytes,
        'path': _ref.path,
        'metadata':
            _metadata == null ? null : buildMetadataUploadMap(_metadata),
      },
    );
  }
}

Map<String, dynamic> buildMetadataUploadMap(StorageMetadata metadata) {
  return <String, dynamic>{
    'cacheControl': metadata.cacheControl,
    'contentDisposition': metadata.contentDisposition,
    'contentLanguage': metadata.contentLanguage,
    'contentType': metadata.contentType,
    'contentEncoding': metadata.contentEncoding,
    'customMetadata': metadata.customMetadata,
  };
}
