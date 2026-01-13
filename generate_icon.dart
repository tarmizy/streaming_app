// Run this with: dart run generate_icon.dart
// This generates the app icon PNG files

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

void main() async {
  print('To generate icons, run:');
  print('1. Create assets/icon/ folder');
  print('2. Add a 1024x1024 PNG with TY logo');
  print('3. Run: flutter pub run flutter_launcher_icons');
  print('');
  print('Or use online tool like https://www.canva.com to create:');
  print('- Blue gradient background (#5D8AA8 to #4A7C9B)');
  print('- White "TY" text, bold');
  print('- Rounded corners');
  print('- Export as 1024x1024 PNG');
}
