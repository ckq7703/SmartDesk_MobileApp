import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/html_helper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../faq/data/repositories/faq_repository.dart';
import '../../../faq/domain/models/faq_model.dart';

class FaqPage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const FaqPage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
  });

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  late final FaqRepository _faqRepository;

  List<FaqModel> _faqs = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedFaqIds = {}; // Track which FAQs are expanded

  @override
  void initState() {
    super.initState();
    _faqRepository = FaqRepository(
      ApiClient(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
    );
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final faqs = await _faqRepository.getFaqs();
      if (mounted) {
        setState(() => _faqs = faqs);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể tải danh sách câu hỏi thường gặp');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FaqModel> get _filteredFaqs {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _faqs;

    return _faqs.where((faq) {
      final name = HtmlHelper.stripHtml(faq.name).toLowerCase();
      final answer = HtmlHelper.stripHtml(faq.answer ?? '').toLowerCase();
      return name.contains(query) || answer.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Câu hỏi thường gặp',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        // automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFaqs,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm câu hỏi...',
          hintStyle: const TextStyle(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(
              Icons.clear,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          )
              : null,
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
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tải câu hỏi thường gặp...',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final filteredFaqs = _filteredFaqs;

    if (filteredFaqs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFaqs,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredFaqs.length,
        itemBuilder: (context, index) {
          final faq = filteredFaqs[index];
          final isExpanded = _expandedFaqIds.contains(faq.id);
          return _buildFaqCard(faq, isExpanded);
        },
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
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
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFaqs,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  Widget _buildEmptyState() {
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
              Icons.help_outline,
              size: 50,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _faqs.isEmpty ? 'Chưa có câu hỏi nào' : 'Không tìm thấy câu hỏi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _faqs.isEmpty
                ? 'Các câu hỏi thường gặp sẽ hiển thị tại đây'
                : 'Thử thay đổi từ khóa tìm kiếm',
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

  Widget _buildFaqCard(FaqModel faq, bool isExpanded) {
    final title = HtmlHelper.stripHtml(faq.name);

    // ✅ Decode HTML entities từ API
    String htmlContent = faq.answer ?? '<p>Không có nội dung</p>';

    // Decode numeric HTML entities (&#60; -> <, &#62; -> >)
    htmlContent = htmlContent
        .replaceAll('&#60;', '<')
        .replaceAll('&#62;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&#34;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(r'\r\n', '\n')  // Remove \r\n
        .replaceAll(r'\n', '\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isExpanded ? AppColors.primary : AppColors.borderColor,
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedFaqIds.remove(faq.id);
                  } else {
                    _expandedFaqIds.add(faq.id);
                  }
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primary.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isExpanded
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.inputBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: isExpanded
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            if (isExpanded) ...[
              const Divider(height: 1, color: AppColors.borderColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            'Trả lời:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Html(
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
                          "h1": Style(
                            fontSize: FontSize(20),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            margin: Margins.only(top: 16, bottom: 8),
                          ),
                          "h2": Style(
                            fontSize: FontSize(18),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            margin: Margins.only(top: 14, bottom: 8),
                          ),
                          "h3": Style(
                            fontSize: FontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            margin: Margins.only(top: 12, bottom: 8),
                          ),
                          "ul": Style(
                            margin: Margins.only(left: 20, bottom: 12),
                            padding: HtmlPaddings.zero,
                          ),
                          "ol": Style(
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
                            padding: HtmlPaddings.symmetric(
                                horizontal: 6, vertical: 2),
                            fontFamily: 'monospace',
                            fontSize: FontSize(13),
                            color: const Color(0xFF1F2937),
                          ),
                          "pre": Style(
                            backgroundColor: const Color(0xFFF3F4F6),
                            padding: HtmlPaddings.all(12),
                            margin: Margins.only(bottom: 12),
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
                            margin: Margins.only(bottom: 12),
                            backgroundColor: const Color(0xFFF9FAFB),
                          ),
                          "img": Style(
                            width: Width(100, Unit.percent),
                            margin: Margins.only(bottom: 12),
                          ),
                          "table": Style(
                            border: Border.all(color: AppColors.borderColor),
                            margin: Margins.only(bottom: 12),
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
                            margin: Margins.symmetric(vertical: 12),
                            border: const Border(
                              top: BorderSide(
                                color: AppColors.borderColor,
                                width: 1,
                              ),
                            ),
                          ),
                        },
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderColor),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cập nhật: ${DateFormatter.formatRelativeTime(faq.dateMod)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


}
