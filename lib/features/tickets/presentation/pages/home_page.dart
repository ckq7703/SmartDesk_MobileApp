import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/ticket_helper.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_model.dart';
import '../widgets/ticket_item.dart';
import '../widgets/feature_card.dart';
import '../widgets/quick_action_button.dart';
import 'create_ticket_page.dart';
import 'ticket_detail_page.dart';
import 'ticket_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/domain/models/user_profile_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../home/presentation/pages/faq_page.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../core/services/notification_service.dart';


class HomePage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const HomePage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TicketRepository _ticketRepository;
  late final AuthRepository _authRepository;
  UserProfileModel? _profile;
  Uint8List? _avatarBytes; // ✅ Cache avatar bytes

  Map<String, int> _ticketStats = {};
  List<TicketModel> _recentTickets = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _ticketRepository = TicketRepository(
      ApiClient(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
    );
    _authRepository = AuthRepository();

    // ✅ Load profile TRƯỚC, rồi load dashboard data
    _initializeData();
  }

  // ✅ Khởi tạo data theo thứ tự
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Load profile trước
      await _loadUserProfile();

      // 2. Load avatar nếu có profile
      if (_profile != null) {
        await _loadAvatar();
      }

      // 3. Load dashboard data
      await Future.wait([
        _loadTicketStats(),
        _loadRecentTickets(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      print('🔵 [DEBUG] Starting to load user profile...');
      final profileRepo = ProfileRepository(
        ApiClient(
          baseUrl: widget.baseUrl,
          sessionToken: widget.sessionToken,
        ),
      );
      final profile = await profileRepo.getUserProfile();

      print('✅ [DEBUG] Profile loaded successfully!');
      print('📋 [DEBUG] User ID: ${profile.userId}');
      print('📋 [DEBUG] Username: ${profile.username}');
      print('📋 [DEBUG] Full name: ${profile.fullName}');

      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Error loading profile: $e');
    }
  }

  // ✅ Load avatar bytes và cache
// ✅ Thêm debug vào hàm _loadAvatar
  Future<void> _loadAvatar() async {
    if (_profile == null) {
      print('⚠️ [DEBUG] Cannot load avatar: _profile is null');
      return;
    }

    print('🔵 [DEBUG] Starting to load avatar for user ID: ${_profile!.userId}');

    try {
      final bytes = await fetchAvatarBytes(
        widget.baseUrl,
        widget.sessionToken,
        _profile!.userId,
      );

      if (bytes != null) {
        print('✅ [DEBUG] Avatar loaded successfully!');
        print('📊 [DEBUG] Avatar size: ${bytes.length} bytes');

        if (mounted) {
          setState(() {
            _avatarBytes = bytes;
          });
        }
      } else {
        print('⚠️ [DEBUG] Avatar bytes is null - API returned no data');
      }
    } catch (e) {
      print('❌ [DEBUG] Error loading avatar: $e');
    }
  }

  Future<Uint8List?> fetchAvatarBytes(
      String baseUrl,
      String sessionToken,
      String userId,
      ) async {
    final url = '$baseUrl/apirest.php/user/$userId/Picture';

    print('🌐 [DEBUG] Fetching avatar from: $url');
    print('🔑 [DEBUG] Session Token: ${sessionToken.substring(0, 10)}...');

    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Session-Token': sessionToken,
        },
      );

      print('📡 [DEBUG] Response status code: ${resp.statusCode}');
      print('📏 [DEBUG] Response content length: ${resp.contentLength}');
      print('📦 [DEBUG] Response headers: ${resp.headers}');

      if (resp.statusCode == 200) {
        print('✅ [DEBUG] Avatar fetch successful - ${resp.bodyBytes.length} bytes');
        return resp.bodyBytes;
      } else {
        print('❌ [DEBUG] Avatar fetch failed with status: ${resp.statusCode}');
        print('📄 [DEBUG] Response body: ${resp.body}');
        return null;
      }
    } catch (e) {
      print('❌ [DEBUG] Exception fetching avatar: $e');
      return null;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadTicketStats(),
        _loadRecentTickets(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTicketStats() async {
    try {
      final tickets = await _ticketRepository.getTickets();

      final stats = <String, int>{
        'total': tickets.length,
        'new': 0,
        'assigned': 0,
        'solved': 0,
        'closed': 0,
      };

      for (final ticket in tickets) {
        final status = ticket.status;
        switch (status) {
          case '1':
            stats['new'] = (stats['new'] ?? 0) + 1;
            break;
          case '2':
            stats['assigned'] = (stats['assigned'] ?? 0) + 1;
            break;
          case '5':
            stats['solved'] = (stats['solved'] ?? 0) + 1;
            break;
          case '6':
            stats['closed'] = (stats['closed'] ?? 0) + 1;
            break;
        }
      }

      setState(() => _ticketStats = stats);
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  Future<void> _loadRecentTickets() async {
    try {
      final tickets = await _ticketRepository.getRecentTickets();
      print('✅ Loaded ${tickets.length} recent tickets');
      if (mounted) {
        setState(() => _recentTickets = tickets);
      }
    } catch (e) {
      print('❌ Error loading recent tickets: $e');
      if (mounted) {
        setState(() => _recentTickets = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: RefreshIndicator(
        onRefresh: _initializeData, // ✅ Refresh toàn bộ data
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildFeatureCards(),
                    const SizedBox(height: 16),
                    _buildQuickActionButtons(),
                    const SizedBox(height: 24),
                    _buildTicketsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đang tải dữ liệu...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng đợi trong giây lát',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lỗi tải dữ liệu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Đã xảy ra lỗi không xác định',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _initializeData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Header đơn giản hóa - không dùng FutureBuilder
  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showUserMenu(context),
            child: _buildAvatarWidget(),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          _buildNotificationBell(),
        ],
      ),
    );
  }

  // ✅ Avatar widget riêng biệt
  Widget _buildAvatarWidget() {
    print('🎨 [DEBUG] Building avatar widget - _avatarBytes is ${_avatarBytes != null ? "NOT null (${_avatarBytes!.length} bytes)" : "NULL"}');

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _avatarBytes != null
            ? Image.memory(
          _avatarBytes!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ [DEBUG] Error displaying avatar image: $error');
            return Image.asset(
              'assets/images/avatar.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            );
          },
        )
            : Image.asset(
          'assets/images/avatar.png',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return StreamBuilder<int>(
      stream: NotificationService.instance.notificationCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        // Nếu không có stream update, lấy từ Future
        if (!snapshot.hasData || snapshot.data == 0) {
          return FutureBuilder<int>(
            future: NotificationService.getUnreadCount(),
            builder: (context, futureSnapshot) {
              final unreadCount = futureSnapshot.data ?? 0;
              return _buildBellIcon(unreadCount);
            },
          );
        }

        final unreadCount = snapshot.data ?? 0;
        return _buildBellIcon(unreadCount);
      },
    );
  }

  Widget _buildBellIcon(int unreadCount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsPage(
                baseUrl: widget.baseUrl,
                sessionToken: widget.sessionToken,
              ),
            ),
          );
          // Refresh badge count after returning from notifications page
          NotificationService.instance.notifyBadgeUpdate();
        },
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }




  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // ✅ Avatar với ảnh từ API hoặc fallback
            Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.width * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: _avatarBytes != null
                    ? Image.memory(
                  _avatarBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/avatar.png',
                      fit: BoxFit.cover,
                    );
                  },
                )
                    : Image.asset(
                  'assets/images/avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Hiển thị tên từ profile hoặc placeholder
            Text(
              _profile?.fullName ?? 'Người dùng',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // ✅ Hiển thị username hoặc email
            Text(
              _profile?.username ?? 'user@smartdesk.com',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuButton(
                  icon: Icons.person_outline,
                  label: 'Hồ sơ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          baseUrl: widget.baseUrl,
                          sessionToken: widget.sessionToken,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuButton(
                  icon: Icons.settings_outlined,
                  label: 'Cài đặt',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuButton(
                  icon: Icons.logout,
                  label: 'Đăng xuất',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          FeatureCard(
            title: 'Ticket',
            subtitle: 'Tạo hoặc theo dõi yêu cầu của bạn',
            imagePath: 'assets/images/2.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketListPage(
                    baseUrl: widget.baseUrl,
                    sessionToken: widget.sessionToken,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FeatureCard(
            title: 'Câu hỏi thường gặp',
            subtitle: 'Xem nhanh hướng dẫn & thắc mắc thường gặp',
            imagePath: 'assets/images/1.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaqPage(
                    baseUrl: widget.baseUrl,
                    sessionToken: widget.sessionToken,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Tạo Ticket',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTicketPage(
                    baseUrl: widget.baseUrl,
                    sessionToken: widget.sessionToken,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),  // ✅ Spacing giữa các buttons
          QuickActionButton(
            icon: Icons.search,
            label: 'Tìm Kiếm',
            onTap: () {},
          ),
          const SizedBox(width: 12),
          QuickActionButton(
            icon: Icons.support_agent,
            label: 'Hỗ trợ',
            onTap: () {},
          ),
          const SizedBox(width: 12),
          QuickActionButton(
            icon: Icons.history,
            label: 'Lịch sử',
            onTap: () {},
          ),
        ],
      ),
    );
  }


  Widget _buildTicketsList() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách ticket gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketListPage(
                        baseUrl: widget.baseUrl,
                        sessionToken: widget.sessionToken,
                      ),
                    ),
                  );
                },
                // ✅ Hiệu ứng nền xanh khi click
                splashColor: AppColors.primary.withOpacity(0.2),
                highlightColor: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),


            ],
          ),
          const SizedBox(height: 16),
          if (_recentTickets.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = _recentTickets[index];
                return TicketItem(
                  ticket: ticket,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketDetailPage(
                          baseUrl: widget.baseUrl,
                          sessionToken: widget.sessionToken,
                          ticketId: ticket.id,
                          ticketTitle: ticket.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có ticket nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các ticket gần đây sẽ hiển thị tại đây',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTicketPage(
                  baseUrl: widget.baseUrl,
                  sessionToken: widget.sessionToken,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Tạo Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
