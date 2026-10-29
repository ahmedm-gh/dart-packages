import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/views/main_screen.dart';

void main() {
  runApp(const DevToolsExtension(child: MainScreen()));
}
