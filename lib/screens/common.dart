import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:image/image.dart' as imglib;
import 'package:passy/common/common.dart';
import 'package:passy/passy_data/biometric_storage_data.dart';
import 'package:passy/passy_data/common.dart';
import 'package:passy/passy_data/screen.dart';
import 'package:passy/passy_flutter/passy_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zxing2/qrcode.dart';

import 'log_screen.dart';
import 'main_screen.dart';
import 'passwords_screen.dart';

const screenToRouteName = {
  Screen.main: MainScreen.routeName,
  Screen.passwords: PasswordsScreen.routeName,
  Screen.notes: '',
  Screen.idCards: '',
  Screen.identities: '',
};

final bool _isMobile = Platform.isAndroid || Platform.isIOS;

Future<bool> bioAuth(String username) async {
  BiometricStorageData _bioData;
  try {
    _bioData = await BiometricStorageData.fromLocker(username);
  } catch (e) {
    return false;
  }
  if (getPassyHash(_bioData.password).toString() !=
      data.getPasswordHash(username)) return false;
  data.info.value.lastUsername = username;
  await data.info.save();
  data.loadAccount(username, getPassyEncrypter(_bioData.password));
  return true;
}

void openUrl(String url) {
  if (_isMobile) {
    FlutterWebBrowser.openWebPage(url: url);
    return;
  }
  launchUrlString(url);
}

Future<String?> backupAccount(
  BuildContext context, {
  required String username,
}) async {
  try {
    MainScreen.shouldLockScreen = false;
    String? _buDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Backup Passy',
      lockParentWindow: true,
    );
    MainScreen.shouldLockScreen = true;
    if (_buDir == null) return null;
    await data.backupAccount(
      username: username,
      outputDirectoryPath: _buDir,
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: const [
          Icon(Icons.save_rounded, color: PassyTheme.darkContentColor),
          SizedBox(width: 20),
          Text('Backup saved'),
        ]),
      ));
    return _buDir;
  } catch (e, s) {
    if (e is FileSystemException) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.save_rounded, color: PassyTheme.darkContentColor),
            SizedBox(width: 20),
            Text('Access denied, try another folder'),
          ]),
        ));
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Row(children: const [
            Icon(Icons.save_rounded, color: PassyTheme.darkContentColor),
            SizedBox(width: 20),
            Text('Could not backup'),
          ]),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => Navigator.pushNamed(context, LogScreen.routeName,
                arguments: e.toString() + '\n' + s.toString()),
          ),
        ));
    }
    rethrow;
  }
}

// CameraImage BGRA8888 -> PNG
// Color
imglib.Image imageFromBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image imageFromYUV420(CameraImage image) {
  var img = imglib.Image(image.width, image.height); // Create Image buffer

  Plane plane = image.planes[0];
  const int shift = (0xFF << 24);

  // Fill image buffer with plane[0] from YUV420_888
  for (int x = 0; x < image.width; x++) {
    for (int planeOffset = 0;
        planeOffset < image.height * image.width;
        planeOffset += image.width) {
      final pixelColor = plane.bytes[planeOffset + x];
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      // Calculate pixel color
      var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

      img.data[planeOffset + x] = newVal;
    }
  }

  return img;
}

imglib.Image? imageFromCameraImage(CameraImage image) {
  try {
    imglib.Image img;
    switch (image.format.group) {
      case ImageFormatGroup.yuv420:
        img = imageFromYUV420(image);
        break;
      case ImageFormatGroup.bgra8888:
        img = imageFromBGRA8888(image);
        break;
      default:
        return null;
    }
    return img;
  } catch (e) {
    //print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}

Result? qrResultFromImage(imglib.Image image) {
  try {
    LuminanceSource _src = RGBLuminanceSource(
        image.width, image.height, Int32List.fromList(image.data));
    BinaryBitmap _bitmap = BinaryBitmap(HybridBinarizer(_src));
    QRCodeReader _reader = QRCodeReader();
    Result _result = _reader.decode(_bitmap);
    return _result;
  } catch (e) {
    return null;
  }
}
