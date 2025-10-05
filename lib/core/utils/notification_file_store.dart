import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NotificationFileStore {
  static const _fileName = 'notifications.json';
  static bool _writing = false;

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    // Đảm bảo tồn tại
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]', flush: true);
    }
    return file;
  }

  static Future<List<Map<String, dynamic>>> readAll() async {
    try {
      final file = await _getFile();
      final txt = await file.readAsString();
      if (txt.trim().isEmpty) return [];
      final decoded = jsonDecode(txt);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      // Log nhẹ, tránh crash trong background
      print('❌ [FILE] read error: $e');
      return [];
    }
  }

  static Future<bool> writeAll(List<Map<String, dynamic>> items) async {
    // Mutex đơn giản chống ghi chồng
    while (_writing) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    _writing = true;
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(items), flush: true);
      return true;
    } catch (e) {
      print('❌ [FILE] write error: $e');
      return false;
    } finally {
      _writing = false;
    }
  }
}
