import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/ticket_helper.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/followup_model.dart';
import '../../domain/models/solution_model.dart';

class TicketDetailPage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;
  final String ticketId;
  final String ticketTitle;

  const TicketDetailPage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
    required this.ticketId,
    required this.ticketTitle,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage>
    with TickerProviderStateMixin {
  late final TicketRepository _ticketRepository;
  late Future<TicketModel> _ticketFuture;
  late Future<List<FollowupModel>> _followupsFuture;
  Future<SolutionModel?>? _solutionFuture; // ✅ Thêm solution future
  late TabController _tabController;
  final _followupController = TextEditingController();
  bool _isAddingFollowup = false;
  final _htmlUnescape = HtmlUnescape(); // ✅ Thêm HTML unescape
  // ✅ Cache user names để tránh gọi API nhiều lần
  final Map<String, String> _userNameCache = {};
// Quản lý lazy loading followups
  List<FollowupModel> _followups = [];
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _ticketRepository = TicketRepository(
      ApiClient(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
    );
    _tabController = TabController(length: 4, vsync: this); // ✅ Đổi từ 3 sang 4 tabs
    _ticketFuture = _ticketRepository.getTicketDetail(widget.ticketId);
    // _followupsFuture = _ticketRepository.getFollowups(widget.ticketId);
    _solutionFuture = _ticketRepository.getTicketSolution(widget.ticketId); // ✅ Load solution
    // Gọi load followups SAU khi ticketRepository đã được khởi tạo
    _loadInitialFollowups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _followupController.dispose();
    super.dispose();
  }

  Future<String> _getUserNameCached(String userId) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    // Fetch from API
    final userName = await _ticketRepository.getUserName(userId);

    // Store in cache
    _userNameCache[userId] = userName;

    return userName;
  }

  Future<void> _loadInitialFollowups() async {
    setState(() => _isLoading = true);

    final result = await _ticketRepository.getFollowups(widget.ticketId, offset: 0, limit: _limit);

    setState(() {
      _followups = result;
      _offset = result.length;
      _hasMore = result.length == _limit;
      _isLoading = false;
    });
  }



  Future<void> _loadMoreFollowups() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _ticketRepository.getFollowups(widget.ticketId, offset: _offset, limit: _limit);

    setState(() {
      _followups.addAll(result);
      _offset += result.length;
      _hasMore = result.length == _limit;
      _isLoadingMore = false;
    });
  }


  String _getTypeText(String? type) {
    switch (type) {
      case '1':
        return 'Sự cố';
      case '2':
        return 'Yêu cầu';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ticket #${widget.ticketId}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Chi tiết'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'Phản hồi'),
            Tab(icon: Icon(Icons.check_circle_outline, size: 20), text: 'Giải pháp'), // ✅ Tab mới
            Tab(icon: Icon(Icons.history, size: 20), text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildFollowupsTab(),
          _buildSolutionTab(), // ✅ Tab mới
          _buildHistoryTab(),
        ],
      ),
    );
  }


  Widget _buildDetailsTab() {
    return FutureBuilder<TicketModel>(
      future: _ticketFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
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
                  'Lỗi tải dữ liệu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final ticket = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(ticket),
              const SizedBox(height: 16),
              _buildInfoGrid(ticket),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(TicketModel ticket) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${ticket.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TicketHelper.getStatusColor(ticket.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    TicketHelper.getStatusText(ticket.status),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticket.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (ticket.content != null && ticket.content!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: _buildHtmlContent(ticket.content!), // ✅ HTML rendering
              ),
            ],
          ],
        ),
      ),
    );
  }

// ✅ Method mới để render HTML content
  Widget _buildHtmlContent(String htmlContent) {
    // Decode HTML entities
    String decodedContent = _htmlUnescape.convert(htmlContent);

    return Html(
      data: decodedContent,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(14),
          lineHeight: const LineHeight(1.6),
          color: AppColors.textSecondary,
        ),
        "p": Style(
          margin: Margins.only(bottom: 10),
          color: AppColors.textSecondary,
        ),
        "h1": Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          margin: Margins.only(top: 12, bottom: 8),
        ),
        "h2": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          margin: Margins.only(top: 12, bottom: 8),
        ),
        "h3": Style(
          fontSize: FontSize(16),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          margin: Margins.only(top: 10, bottom: 6),
        ),
        "ul": Style(
          margin: Margins.only(left: 20, bottom: 10),
          padding: HtmlPaddings.zero,
        ),
        "ol": Style(
          margin: Margins.only(left: 20, bottom: 10),
          padding: HtmlPaddings.zero,
        ),
        "li": Style(
          margin: Margins.only(bottom: 4),
          color: AppColors.textSecondary,
        ),
        "a": Style(
          color: AppColors.primary,
          textDecoration: TextDecoration.underline,
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        "b": Style(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "i": Style(
          fontStyle: FontStyle.italic,
        ),
        "code": Style(
          backgroundColor: const Color(0xFFE5E7EB),
          padding: HtmlPaddings.symmetric(horizontal: 6, vertical: 2),
          fontFamily: 'monospace',
          fontSize: FontSize(13),
          color: const Color(0xFF1F2937),
        ),
        "pre": Style(
          backgroundColor: const Color(0xFFF3F4F6),
          padding: HtmlPaddings.all(12),
          margin: Margins.only(bottom: 10),
          border: Border.all(color: AppColors.borderColor),
        ),
        "blockquote": Style(
          border: const Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 4,
            ),
          ),
          padding: HtmlPaddings.only(left: 12),
          margin: Margins.only(bottom: 10),
          backgroundColor: const Color(0xFFF9FAFB),
        ),
        "img": Style(
          width: Width(100, Unit.percent),
          margin: Margins.only(bottom: 10),
        ),
        "table": Style(
          border: Border.all(color: AppColors.borderColor),
          margin: Margins.only(bottom: 10),
          width: Width(100, Unit.percent),
        ),
        "th": Style(
          border: Border.all(color: AppColors.borderColor),
          padding: HtmlPaddings.all(8),
          backgroundColor: const Color(0xFFF3F4F6),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        "td": Style(
          border: Border.all(color: AppColors.borderColor),
          padding: HtmlPaddings.all(8),
          color: AppColors.textSecondary,
        ),
        "hr": Style(
          margin: Margins.symmetric(vertical: 10),
          border: const Border(
            top: BorderSide(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
        ),
      },
    );
  }


  Widget _buildInfoGrid(TicketModel ticket) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Ưu tiên',
                TicketHelper.getPriorityText(ticket.priority),
                Icons.flag,
                TicketHelper.getPriorityColor(ticket.priority),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Loại',
                _getTypeText(ticket.type),
                Icons.category,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Người tạo',
                'User #${ticket.usersIdRecipient ?? 'N/A'}',
                Icons.person,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Ngày tạo',
                ticket.dateCreation?.split(' ').first ?? 'N/A',
                Icons.calendar_today,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Cập nhật lần cuối',
          DateFormatter.formatRelativeTime(ticket.dateMod),
          Icons.update,
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowupsTab() {
    return Column(
      children: [
        // Form thêm phản hồi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm phản hồi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _followupController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung phản hồi...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isAddingFollowup ? null : _addFollowup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isAddingFollowup
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Gửi phản hồi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Danh sách phản hồi với lazy loading
        Expanded(
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          )
              : _followups.isEmpty && !_isLoadingMore
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chưa có phản hồi nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy là người đầu tiên thêm phản hồi\ncho ticket này',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
              : NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (!_isLoadingMore &&
                  _hasMore &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 100) {
                _loadMoreFollowups();
                return true;
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _followups.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _followups.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                  );
                }
                final followup = _followups[index];
                return _buildFollowupCard(followup);
              },
            ),
          ),
        ),
      ],
    );
  }


// ✅ Method gửi phản hồi với validation và error handling
  Future<void> _addFollowup() async {
    final content = _followupController.text.trim();

    // Validation
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung phản hồi'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (content.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nội dung phản hồi phải có ít nhất 5 ký tự'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAddingFollowup = true);

    try {
      final success = await _ticketRepository.addFollowup(
        ticketId: widget.ticketId,
        content: content,
      );

      if (success) {
        _followupController.clear();

        // Reload followups
// Reload followups từ đầu
        await _loadInitialFollowups();


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Phản hồi đã được gửi thành công',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Không thể gửi phản hồi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lỗi: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingFollowup = false);
      }
    }
  }


// ✅ Method mới để build followup card với HTML
  Widget _buildFollowupCard(FollowupModel followup) {
    String htmlContent = followup.content ?? '<p>Không có nội dung</p>';
    htmlContent = _htmlUnescape.convert(htmlContent);

    // ✅ userId là username string rồi nhờ expand_dropdowns=true
    final userName = followup.userId;

    // Capitalize first letter
    final displayName = userName.isNotEmpty
        ? userName[0].toUpperCase() + userName.substring(1)
        : 'Unknown';

    final userInitial = userName.isNotEmpty
        ? userName[0].toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatRelativeTime(followup.dateCreation),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderColor),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Html(
                  data: htmlContent,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      lineHeight: const LineHeight(1.6),
                      color: AppColors.textSecondary,
                    ),
                    "p": Style(
                      margin: Margins.only(bottom: 10),
                      color: AppColors.textSecondary,
                    ),
                    "h1, h2, h3, h4, h5, h6": Style(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      margin: Margins.only(top: 10, bottom: 6),
                    ),
                    "ul, ol": Style(
                      margin: Margins.only(left: 20, bottom: 10),
                      padding: HtmlPaddings.zero,
                    ),
                    "li": Style(
                      margin: Margins.only(bottom: 4),
                      color: AppColors.textSecondary,
                    ),
                    "a": Style(
                      color: AppColors.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                    "strong, b": Style(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    "em, i": Style(
                      fontStyle: FontStyle.italic,
                    ),
                    "code": Style(
                      backgroundColor: const Color(0xFFE5E7EB),
                      padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                      fontFamily: 'monospace',
                      fontSize: FontSize(13),
                    ),
                    "pre": Style(
                      backgroundColor: const Color(0xFFF3F4F6),
                      padding: HtmlPaddings.all(10),
                      margin: Margins.only(bottom: 10),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    "blockquote": Style(
                      border: const Border(
                        left: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      padding: HtmlPaddings.only(left: 10),
                      margin: Margins.only(bottom: 10),
                      backgroundColor: const Color(0xFFF9FAFB),
                    ),
                    "img": Style(
                      width: Width(100, Unit.percent),
                      margin: Margins.only(bottom: 10),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.history,
              size: 50,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Lịch sử sẽ được phát triển sau',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSolutionTab() {
    return FutureBuilder<SolutionModel?>(
      future: _solutionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
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
                  'Lỗi tải giải pháp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final solution = snapshot.data;

        if (solution == null || solution.content == null || solution.content!.isEmpty) {
          return _buildNoSolutionState();
        }

        return _buildSolutionContent(solution);
      },
    );
  }

  Widget _buildNoSolutionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 60,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có giải pháp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Giải pháp sẽ được cập nhật khi ticket được giải quyết',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionContent(SolutionModel solution) {
    // Decode HTML entities
    String htmlContent = solution.content ?? '<p>Không có nội dung</p>';
    htmlContent = _htmlUnescape.convert(htmlContent);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: AppColors.success,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.success,
                              Color(0xFF34D399),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giải pháp',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ticket đã được giải quyết',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.success,
                              Color(0xFF34D399),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nội dung giải pháp:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Solution Content Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Html(
                      data: htmlContent,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(14),
                          lineHeight: const LineHeight(1.6),
                          color: AppColors.textSecondary,
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 12),
                          color: AppColors.textSecondary,
                        ),
                        "h1, h2, h3, h4, h5, h6": Style(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          margin: Margins.only(top: 12, bottom: 8),
                        ),
                        "ul, ol": Style(
                          margin: Margins.only(left: 20, bottom: 12),
                          padding: HtmlPaddings.zero,
                        ),
                        "li": Style(
                          margin: Margins.only(bottom: 6),
                          color: AppColors.textSecondary,
                        ),
                        "a": Style(
                          color: AppColors.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                        "strong, b": Style(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        "em, i": Style(
                          fontStyle: FontStyle.italic,
                        ),
                        "code": Style(
                          backgroundColor: const Color(0xFFE5E7EB),
                          padding: HtmlPaddings.symmetric(
                              horizontal: 6, vertical: 2),
                          fontFamily: 'monospace',
                          fontSize: FontSize(13),
                        ),
                        "pre": Style(
                          backgroundColor: const Color(0xFFF3F4F6),
                          padding: HtmlPaddings.all(12),
                          margin: Margins.only(bottom: 12),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        "img": Style(
                          width: Width(100, Unit.percent),
                          margin: Margins.only(bottom: 12),
                        ),
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Người giải quyết: ${solution.userId ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ngày giải quyết: ${DateFormatter.formatRelativeTime(solution.dateCreation)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
