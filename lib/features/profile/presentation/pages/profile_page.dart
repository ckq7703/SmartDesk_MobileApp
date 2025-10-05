import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../domain/models/user_profile_model.dart';
import 'change_password_page.dart'; // ✅ Thêm import
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/avatar_cache.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';


class ProfilePage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const ProfilePage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileRepository _profileRepository;
  late final AuthRepository _authRepository; // ✅ Thêm AuthRepository
  UserProfileModel? _profile;
  bool _isLoading = true;
  String? _error;
  bool _isLoggingOut = false; // ✅ Loading state cho logout
  File? _avatarFile; // Hoặc Uint8List _avatarBytes;
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepository(
      ApiClient(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
    );
    _authRepository = AuthRepository(); // ✅ Initialize AuthRepository

    _loadCachedAvatar();

    _loadProfile();
    print('Loaded avatar base64: $_avatarBase64');

  }

  Future<Uint8List?> fetchAvatarBytes() async {
    final url = '${widget.baseUrl}/apirest.php/user/${_profile!.userId}/Picture';
    final resp = await http.get(
      Uri.parse(url),
      headers: {
        'Session-Token': widget.sessionToken,
        // hoặc headers khác nếu cần
      },
    );
    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    }
    return null;
  }

  Future<void> _loadCachedAvatar() async {
    final cached = await AvatarCache.loadAvatarBase64();
    if (cached != null) {
      setState(() {
        _avatarBase64 = cached;
        print('Loaded avatar base64: $_avatarBase64');

      });
    }

    // Sau đó fetch avatar mới cập nhật từ server
    _fetchAndCacheAvatar();
  }

  Future<void> _fetchAndCacheAvatar() async {
    if (_profile == null) return;
    final base64Str = await _profileRepository.getAvatarBase64(_profile!.userId);
    if (base64Str != null && base64Str != _avatarBase64) {
      await AvatarCache.saveAvatarBase64(base64Str);
      setState(() {
        _avatarBase64 = base64Str;
        print('Loaded avatar base64: $_avatarBase64');

      });
    }
  }



  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _profileRepository.getUserProfile();
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lỗi tải thông tin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_profile == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildInfoSection(),
              const SizedBox(height: 16),
              _buildSettingsSection(),
              const SizedBox(height: 16),
              _buildActionsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Check if collapsed
          final isCollapsed = constraints.maxHeight <= kToolbarHeight + 50;

          return FlexibleSpaceBar(
            centerTitle: true,
            // ✅ Chỉ hiển thị title khi collapsed
            title: isCollapsed
                ? const Text(
              'Hồ sơ của tôi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )
                : null,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                        height: 100,
                      ),
                      // ✅ Text chỉ hiển thị khi expanded
                      if (!isCollapsed)
                        const Text(
                          'Hồ sơ của tôi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          _buildAvatar(),

          const SizedBox(height: 16),
          // Name
          Text(
            _profile!.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@${_profile!.username}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Profile Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _profile!.profileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoItem(
            icon: Icons.badge_outlined,
            label: 'Họ',
            value: _profile!.realName,
          ),
          _buildInfoItem(
            icon: Icons.person_outline,
            label: 'Tên',
            value: _profile!.firstName,
          ),
          _buildInfoItem(
            icon: Icons.account_circle_outlined,
            label: 'Tên đăng nhập',
            value: _profile!.username,
          ),
          _buildInfoItem(
            icon: Icons.business_outlined,
            label: 'Đơn vị',
            value: _profile!.entityName,
          ),
          _buildInfoItem(
            icon: Icons.language_outlined,
            label: 'Ngôn ngữ',
            value: _getLanguageName(_profile!.language),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Cài đặt hệ thống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoItem(
            icon: Icons.calendar_today_outlined,
            label: 'Định dạng ngày',
            value: _getDateFormatName(_profile!.dateFormat),
          ),
          _buildInfoItem(
            icon: Icons.format_list_numbered_outlined,
            label: 'Số mục trên trang',
            value: '${_profile!.listLimit}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.lock_outline,
            label: 'Đổi mật khẩu',
            color: AppColors.primary,
            onTap: () {
              if (_profile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(
                      baseUrl: widget.baseUrl,
                      sessionToken: widget.sessionToken,
                      userId: _profile!.userId, // ✅ Pass userId
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            label: 'Đăng xuất',
            color: AppColors.error,
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return FutureBuilder<Uint8List?>(
      future: fetchAvatarBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(radius: 50, child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // fallback
          return CircleAvatar(
            radius: 50,
            child: Text(_profile!.initials, style: const TextStyle(fontSize: 40)),
          );
        }
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(snapshot.data!),
        );
      },
    );
  }



  String _getLanguageName(String code) {
    switch (code) {
      case 'en_US':
        return 'English (US)';
      case 'vi_VN':
        return 'Tiếng Việt';
      case 'fr_FR':
        return 'Français';
      default:
        return code;
    }
  }

  String _getDateFormatName(String format) {
    switch (format) {
      case '0':
        return 'YYYY-MM-DD';
      case '1':
        return 'DD-MM-YYYY';
      case '2':
        return 'MM-DD-YYYY';
      default:
        return format;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isLoggingOut, // Không cho dismiss khi đang logout
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            content: const Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoggingOut ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: _isLoggingOut
                    ? null
                    : () async {
                  setDialogState(() => _isLoggingOut = true);
                  await _handleLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Đăng xuất'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ Handle logout logic
  Future<void> _handleLogout() async {
    try {
      // Call logout API
      final success = await _authRepository.logout(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      );

      if (!mounted) return;

      // Close dialog
      Navigator.pop(context);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đăng xuất thành công'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navigate to login screen and clear all previous routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/', // Login route
            (route) => false, // Remove all routes
      );
    } catch (e) {
      if (!mounted) return;

      // Close dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Lỗi đăng xuất: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Still navigate to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
            (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }
}
