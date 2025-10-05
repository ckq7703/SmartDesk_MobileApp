import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepository {
  final ApiClient apiClient;

  ProfileRepository(this.apiClient);

  Future<UserProfileModel> getUserProfile() async {
    try {
      final response = await apiClient.get('/apirest.php/getFullSession');

      print('📡 Profile Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfileModel.fromJson(data);
      }

      throw Exception('Không thể tải thông tin người dùng: HTTP ${response.statusCode}');
    } catch (e) {
      print('❌ Error loading profile: $e');
      rethrow;
    }
  }



  // ✅ Thêm method đổi mật khẩu
  Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔐 Changing password for user: $userId');

      final response = await apiClient.put(
        '/apirest.php/User/$userId',
        {
          'input': {
            'password': currentPassword,
            'password2': newPassword,
          }
        },
      );

      print('📡 Change password response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Password changed successfully');
        return true;
      }

      // Parse error message
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData.toString());
      } catch (e) {
        throw Exception('Không thể đổi mật khẩu: ${response.body}');
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      rethrow;
    }
  }

  Future<String?> getAvatarBase64(String userId) async {
    try {
      final response = await apiClient.get('/apirest.php/user/$userId/Picture');
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Giả sử response.body là chuỗi base64 thuần
        return response.body;
      }
      print('Avatar API returned status ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error loading avatar from API: $e');
      return null;
    }
  }




}
