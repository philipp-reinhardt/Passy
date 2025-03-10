import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:passy/common/assets.dart';
import 'package:passy/passy_flutter/passy_flutter.dart';
import 'package:passy/screens/confirm_import_screen.dart';
import 'package:passy/screens/main_screen.dart';

import 'export_and_import_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  static const routeName = '${ExportAndImportScreen.routeName}/import';

  @override
  State<StatefulWidget> createState() => _ImportScreen();
}

class _ImportScreen extends State<ImportScreen> {
  void _onPassyImportPressed() {
    MainScreen.shouldLockScreen = false;
    FilePicker.platform
        .pickFiles(
      dialogTitle: 'Import from Passy',
      type: FileType.custom,
      allowedExtensions: ['zip'],
      lockParentWindow: true,
    )
        .then(
      (_pick) {
        MainScreen.shouldLockScreen = true;
        if (_pick == null) return;
        Navigator.pushNamed(
          context,
          ConfirmImportScreen.routeName,
          arguments: _pick.files[0].path,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: PassyTheme.appBarButtonPadding,
          splashRadius: PassyTheme.appBarButtonSplashRadius,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Import'),
        centerTitle: true,
      ),
      body: ListView(children: [
        PassyPadding(ThreeWidgetButton(
          center: const Text('Passy import'),
          left: Padding(
            padding: const EdgeInsets.only(right: 30),
            child: SvgPicture.asset(
              logoCircleSvg,
              width: 30,
              color: PassyTheme.lightContentColor,
            ),
          ),
          right: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: _onPassyImportPressed,
        )),
      ]),
    );
  }
}
