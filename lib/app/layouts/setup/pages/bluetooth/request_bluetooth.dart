import 'package:openbubbles/helpers/ui/theme_helpers.dart';
import 'package:openbubbles/app/layouts/setup/pages/page_template.dart';
import 'package:openbubbles/main.dart';
import 'package:openbubbles/services/services.dart';
import 'package:openbubbles/utils/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_io/io.dart';

class RequestBluetooth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SetupPageTemplate(
      title: "Nearby Devices",
      subtitle: "Apple uses proximity detection to securely transfer account data during login.",
      onNextPressed: () async {
        if ((fs.androidInfo?.version.sdkInt ?? 0) >= 31) {
          final statuses = await [
            Permission.bluetoothAdvertise,
            Permission.bluetoothConnect,
          ].request();

          final ok = statuses.values.every((s) => s.isGranted);
          if (!ok) {
            return true;
          }
        }

        try {
          await mcs.invokeMethod("enable-bt", {"request": true});
        } catch (e, s) {
          Logger.error("Failed to enable bt", error: e, trace: s);
          return false;
        }

        return true;
      },
    );
  }
}
