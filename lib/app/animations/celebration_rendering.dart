import 'package:openbubbles/app/animations/celebration_class.dart';
import 'package:openbubbles/app/animations/fireworks_rendering.dart';
import 'package:flutter/material.dart';

class Celebration extends LeafRenderObjectWidget {
  Celebration({
    super.key,
    required this.controller,
  });

  final CelebrationController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFireworks(
      controller: controller,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFireworks renderObject) {
    renderObject.controller = controller;
  }
}