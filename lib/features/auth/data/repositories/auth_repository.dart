import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/session_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';


class AuthRepository {
  Future<SessionModel> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    // Sử dụng getFullSession endpoint
    final url = Uri.parse('$base${ApiConstants.getFullSession}');
    final basic = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basic,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Đăng nhập thất bại. Vui lòng kiểm tra thông tin.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>?;

    if (session == null) {
      throw Exception('Không nhận được session đầy đủ.');
    }

    // Lấy các trường cần thiết
    final validId   = session['valid_id']   as String?;
    final glpiID    = session['glpiID']     as int?;
    final glpiname  = session['glpiname']   as String?;

    if (validId == null || glpiID == null || glpiname == null) {
      throw Exception('Thiếu dữ liệu xác thực từ server.');
    }

    // Tạo model session mới (mở rộng để lưu thêm glpiID, glpiname)
    final sessionModel = SessionModel(
      sessionToken: validId,
      baseUrl:      baseUrl,
      userId:       glpiID.toString(),
      username:     glpiname,
    );

    // Lưu session
    await saveSession(sessionModel);

    // Gửi FCM token lên server
    try {
      await NotificationService.instance.sendTokenToServer(
        baseUrl: baseUrl,
        userId:  glpiID,
      );
    } catch (_) {}

    return sessionModel;
  }



  // ✅ Thêm method logout
  Future<bool> logout({
    required String baseUrl,
    required String sessionToken,
  }) async {
    try {
      final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final killSessionUrl = Uri.parse('$base${ApiConstants.killSession}');

      print('🔐 Logging out...');

      final response = await http.get(
        killSessionUrl,
        headers: {
          'Content-Type': 'application/json',
          'Session-Token': sessionToken,
        },
      );

      print('📡 Logout response: ${response.statusCode}');

      // Clear saved session
      await clearSession();

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error during logout: $e');
      // Clear session anyway
      await clearSession();
      return true; // Return true to proceed with logout
    }
  }

  // ✅ Method để clear session từ SharedPreferences
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_data');
      print('✅ Session cleared from storage');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  // ✅ Method để lưu session (nếu chưa có)
  Future<void> saveSession(SessionModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = jsonEncode(session.toJson());
      await prefs.setString('session_data', sessionJson);
      print('✅ Session saved to storage');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  // ✅ Method để lấy saved session
  Future<SessionModel?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('session_data');

      if (sessionJson != null) {
        final data = jsonDecode(sessionJson);
        return SessionModel.fromJson(data);
      }

      return null;
    } catch (e) {
      print('❌ Error loading saved session: $e');
      return null;
    }
  }
}
