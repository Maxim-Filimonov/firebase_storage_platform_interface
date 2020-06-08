import 'dart:async';

import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_firebase_storage.dart';

import '../firebase_storage_common_interface.dart';
import 'platform_interface/file.dart';

class StorageFileDownloadTask {
  StorageFileDownloadTask(this._firebaseStorage, this._path, this._file);

  final FirebaseStoragePlatform _firebaseStorage;
  final String _path;
  final File _file;

  Future<void> start() async {
    try {
      final int totalByteCount =
          await MethodChannelFirebaseStorage.channel.invokeMethod<int>(
        "StorageReference#writeToFile",
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'filePath': _file.path,
          'path': _path,
        },
      );
      _completer
          .complete(FileDownloadTaskSnapshot(totalByteCount: totalByteCount));
    } catch (e) {
      _completer.completeError(e);
    }
  }

  Completer<FileDownloadTaskSnapshot> _completer =
      Completer<FileDownloadTaskSnapshot>();
  Future<FileDownloadTaskSnapshot> get future => _completer.future;
}

class FileDownloadTaskSnapshot {
  FileDownloadTaskSnapshot({this.totalByteCount});
  final int totalByteCount;
}
