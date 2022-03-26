import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:universal_io/io.dart';

import 'common.dart';

class AccountInfo {
  String username;
  String icon;
  Color color;
  final String path;

  String get passwordHash => _passwordHash;

  String _passwordHash;
  final File _file;

  Future<void> save() => _file.writeAsString(jsonEncode(this));

  void saveSync() => _file.writeAsStringSync(jsonEncode(this));

  AccountInfo._(
    this.path,
    this.username,
    this._passwordHash, {
    required this.icon,
    required this.color,
    required File file,
  }) : _file = file;

  AccountInfo(
    this.path,
    this.username,
    String password, {
    required this.icon,
    required this.color,
  })  : _passwordHash = getPasswordHash(password),
        _file = File(path + Platform.pathSeparator + 'info.json') {
    _file.createSync(recursive: true);
    saveSync();
  }

  factory AccountInfo.fromDirectory(String path) {
    File _file = File(path + Platform.pathSeparator + 'info.json');
    Map<String, dynamic> _json = jsonDecode(_file.readAsStringSync());
    AccountInfo _account = AccountInfo._(
      path,
      _json['username'],
      _json['passwordHash'],
      icon: _json['icon'],
      color: Color(_json['color']),
      file: _file,
    );
    return _account;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'username': username,
        'passwordHash': _passwordHash,
        'icon': icon,
        'color': color.value,
      };
}
