import 'package:flutter/material.dart';
import 'app.dart';
// Trong main.dart
import 'package:smartdesk/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';  // ✅ Thêm dòng này


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartDesk());
}
