import 'package:shared_preferences/shared_preferences.dart';

class AvatarCache {
  static const _keyAvatar = 'user_avatar_base64';

  static Future<void> saveAvatarBase64(String base64Str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatar, base64Str);
  }

  static Future<String?> loadAvatarBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAvatar);
  }

  static Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAvatar);
  }
}
