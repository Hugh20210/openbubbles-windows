import 'package:openbubbles/helpers/types/constants.dart';
import 'package:openbubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NextButton extends StatelessWidget {
  const NextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ss.settings.skin.value != Skins.Material ? Icon(
        ss.settings.skin.value != Skins.Material
            ? CupertinoIcons.chevron_right
            : Icons.arrow_forward,
        color: context.theme.colorScheme.outline.withOpacity(0.5),
        size: 18,
      ) : const SizedBox.shrink());
  }
}