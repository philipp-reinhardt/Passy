import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:universal_io/io.dart';

import 'common.dart';
import 'json_convertable.dart';
import 'saveable_file_base.dart';

class EncryptedJsonFile<T extends JsonConvertable> implements SaveableFileBase {
  final T value;
  final File _file;
  Encrypter _encrypter;
  set encrypter(Encrypter encrypter) => _encrypter = encrypter;

  @override
  Future<void> save() =>
      _file.writeAsString(encrypt(jsonEncode(value), encrypter: _encrypter));
  @override
  void saveSync() => _file
      .writeAsStringSync(encrypt(jsonEncode(value), encrypter: _encrypter));

  EncryptedJsonFile(this._file, this._encrypter, {required this.value});
}
