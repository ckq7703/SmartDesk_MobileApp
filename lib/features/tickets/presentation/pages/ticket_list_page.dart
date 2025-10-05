import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/ticket_helper.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_model.dart';
import '../widgets/ticket_list_item.dart';
import 'ticket_detail_page.dart';
import 'create_ticket_page.dart';

class TicketListPage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const TicketListPage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
  });

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  late final TicketRepository _ticketRepository;
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  List<TicketModel> _allTickets = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _ticketRepository = TicketRepository(
      ApiClient(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialTickets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Listener để detect khi scroll xuống cuối
  void _onScroll() {
    print('🔵 Scroll position: ${_scrollController.position.pixels}');
    print('📏 Max scroll extent: ${_scrollController.position.maxScrollExtent}');
    print('⚙️ _isLoadingMore: $_isLoadingMore, _hasMore: $_hasMore, _isLoading: $_isLoading');

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      print('✅ Reached scroll threshold - attempting to load more');
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        print('🚀 Loading more tickets...');
        _loadMoreTickets();
      } else {
        print('⛔ Cannot load: _isLoadingMore=$_isLoadingMore, _hasMore=$_hasMore, _isLoading=$_isLoading');
      }
    }
  }


  // ✅ Load tickets lần đầu
  Future<void> _loadInitialTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _allTickets = [];
      _hasMore = true;
    });

    try {
      final tickets = await _ticketRepository.getTickets(
        start: 0,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _isLoading = false;
          // ✅ Nếu số tickets nhận được < _pageSize thì hết data
          // Nếu = _pageSize thì vẫn còn có thể có data
          _hasMore = tickets.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ✅ Load thêm tickets khi scroll
  Future<void> _loadMoreTickets() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final tickets = await _ticketRepository.getTickets(
        start: nextPage * _pageSize,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _allTickets.addAll(tickets);
          _currentPage = nextPage;
          // ✅ Nếu số tickets nhận được < _pageSize thì hết data
          _hasMore = tickets.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thêm: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ Refresh danh sách
  Future<void> _refresh() async {
    await _loadInitialTickets();
  }

  // ✅ Filter và search tickets
  // ✅ Filter và search tickets
  List<TicketModel> _getFilteredTickets() {
    var filtered = _allTickets;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((ticket) {
        switch (_selectedFilter) {
          case 'new':
            return ticket.status == '1';
          case 'assigned':
            return ticket.status == '2';
          case 'in_progress':
            return ticket.status == '3';
          case 'solved':
            return ticket.status == '5';
          case 'closed':
            return ticket.status == '6';
          default:
            return true;
        }
      }).toList();
    }

    // ✅ Apply search filter với null-safety
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((ticket) {
        final name = ticket.name.toLowerCase();
        final id = ticket.id.toLowerCase();
        final content = (ticket.content ?? '').toLowerCase(); // ✅ Handle null content

        return name.contains(query) ||
            id.contains(query) ||
            content.contains(query);
      }).toList();
    }

    return filtered;
  }


  // ✅ Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Tìm kiếm ticket'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên hoặc ID ticket...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ✅ Search bar nếu đang tìm kiếm
          if (_searchQuery.isNotEmpty) _buildSearchBanner(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : _error != null
                ? _buildErrorState(_error!)
                : _buildTicketList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Danh sách Ticket',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refresh,
          tooltip: 'Làm mới',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Tìm kiếm',
        ),
      ],
    );
  }

  // ✅ Banner hiển thị khi đang search
  Widget _buildSearchBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tìm kiếm: "$_searchQuery"',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.primary,
            ),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Mới', 'new'),
            const SizedBox(width: 8),
            _buildFilterChip('Đã gán', 'assigned'),
            const SizedBox(width: 8),
            _buildFilterChip('Đang xử lý', 'in_progress'),
            const SizedBox(width: 8),
            _buildFilterChip('Đã giải quyết', 'solved'),
            const SizedBox(width: 8),
            _buildFilterChip('Đã đóng', 'closed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: AppColors.inputBackground,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderColor,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    final filteredTickets = _getFilteredTickets();

    if (filteredTickets.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filteredTickets.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // ✅ Loading indicator ở cuối danh sách
          if (index == filteredTickets.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            );
          }

          final ticket = filteredTickets[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TicketListItem(
              ticket: ticket,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TicketDetailPage(
                      baseUrl: widget.baseUrl,
                      sessionToken: widget.sessionToken,
                      ticketId: ticket.id,
                      ticketTitle: ticket.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.inbox_outlined,
                size: 60,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không có ticket nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy ticket phù hợp'
                  : _selectedFilter == 'all'
                  ? 'Chưa có ticket nào trong hệ thống'
                  : 'Không có ticket nào phù hợp với bộ lọc',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateTicketPage(
                      baseUrl: widget.baseUrl,
                      sessionToken: widget.sessionToken,
                    ),
                  ),
                );

                if (result == true && mounted) {
                  _refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo ticket mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
                color: const Color(0xFFFEE2E2),
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateTicketPage(
                  baseUrl: widget.baseUrl,
                  sessionToken: widget.sessionToken,
                ),
              ),
            );

            if (result == true && mounted) {
              _refresh();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Tạo ticket',
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
}
