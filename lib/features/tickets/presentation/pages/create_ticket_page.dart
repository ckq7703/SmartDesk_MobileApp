import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ticket_helper.dart';
import '../../data/repositories/ticket_repository.dart';
import 'ticket_detail_page.dart';
import '../widgets/bottom_sheet_field.dart';

class CreateTicketPage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const CreateTicketPage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
  });

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  late final TicketRepository _ticketRepository;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = '1';
  String _selectedPriority = '3';
  String _selectedUrgency = '3';
  String _selectedImpact = '3';
  String? _selectedCategory;

  bool _isCreating = false;
  String? _errorMessage;

  final Map<String, String> _typeOptions = {
    '1': 'Sự cố (Incident)',
    '2': 'Yêu cầu (Request)',
  };

  final Map<String, String> _priorityOptions = {
    '1': 'Rất thấp',
    '2': 'Thấp',
    '3': 'Trung bình',
    '4': 'Cao',
    '5': 'Rất cao',
    '6': 'Khẩn cấp',
  };

  final Map<String, String> _urgencyOptions = {
    '1': 'Rất thấp',
    '2': 'Thấp',
    '3': 'Trung bình',
    '4': 'Cao',
    '5': 'Rất cao',
    '6': 'Khẩn cấp',
  };

  final Map<String, String> _impactOptions = {
    '1': 'Rất thấp',
    '2': 'Thấp',
    '3': 'Trung bình',
    '4': 'Cao',
    '5': 'Rất cao',
    '6': 'Khẩn cấp',
  };

  @override
  void initState() {
    super.initState();
    _ticketRepository = TicketRepository(
      ApiClient(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final ticketId = await _ticketRepository.createTicket(
        name: _titleController.text.trim(),
        content: _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        urgency: _selectedUrgency,
        impact: _selectedImpact,
        categoryId: _selectedCategory,
      );

      if (mounted) {
        await _showSuccessDialog(ticketId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tạo ticket: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _showSuccessDialog(String ticketId) async {
    final confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    confettiController.play();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Confetti
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      particleDrag: 0.05,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.1,
                      shouldLoop: false,
                      colors: const [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.success,
                        AppColors.warning,
                      ],
                    ),
                  ),
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.success,
                          Color(0xFF34D399),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Tạo ticket thành công!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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
                      Icons.confirmation_number,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ticket #$ticketId',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ticket của bạn đã được tạo và gửi đến bộ phận hỗ trợ.\nBạn có thể theo dõi trạng thái ticket bất cứ lúc nào.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        confettiController.dispose();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(true);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Về trang chủ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppColors.borderColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        confettiController.dispose();
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => TicketDetailPage(
                              baseUrl: widget.baseUrl,
                              sessionToken: widget.sessionToken,
                              ticketId: ticketId,
                              ticketTitle: _titleController.text.trim(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Xem chi tiết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tạo ticket mới',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createTicket,
            child: _isCreating
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Tạo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              _buildPriorityCard(),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 16),
              ],
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Thông tin cơ bản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề ticket *',
                hintText: 'Mô tả ngắn gọn vấn đề...',
                prefixIcon: const Icon(Icons.title, size: 20),
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
                counterText: '',
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Vui lòng nhập tiêu đề ticket';
                }
                if (value!.trim().length < 5) {
                  return 'Tiêu đề phải có ít nhất 5 ký tự';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
              maxLength: 255,
            ),
            const SizedBox(height: 16),
            // ✅ Thay DropdownButtonFormField bằng BottomSheetField
            BottomSheetField(
              label: 'Loại ticket',
              value: _selectedType,
              valueText: _typeOptions[_selectedType] ?? '',
              icon: Icons.category,
              leadingIcon: Icons.category,
              options: _typeOptions,
              showColorIndicator: false,
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) =>
              value == null ? 'Vui lòng chọn loại ticket' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết *',
                hintText: 'Mô tả chi tiết vấn đề, các bước tái hiện...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description, size: 20),
                ),
                alignLabelWithHint: true,
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
              ),
              maxLines: 5,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Vui lòng nhập mô tả chi tiết';
                }
                if (value!.trim().length < 10) {
                  return 'Mô tả phải có ít nhất 10 ký tự';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard() {
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TicketHelper.getPriorityColor(_selectedPriority)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flag,
                    color: TicketHelper.getPriorityColor(_selectedPriority),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mức độ ưu tiên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TicketHelper.getPriorityColor(_selectedPriority),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ưu tiên = Tầm quan trọng × Mức độ khẩn cấp',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ✅ Thay Row của 2 dropdown bằng BottomSheetField
            BottomSheetField(
              label: 'Mức độ khẩn cấp',
              value: _selectedUrgency,
              valueText: _urgencyOptions[_selectedUrgency] ?? '',
              icon: Icons.speed,
              leadingIcon: Icons.speed,
              leadingIconColor: TicketHelper.getPriorityColor(_selectedUrgency),
              options: _urgencyOptions,
              onChanged: (value) => setState(() => _selectedUrgency = value),
              validator: (value) =>
              value == null ? 'Vui lòng chọn mức độ khẩn cấp' : null,
            ),
            const SizedBox(height: 12),
            BottomSheetField(
              label: 'Tầm quan trọng',
              value: _selectedImpact,
              valueText: _impactOptions[_selectedImpact] ?? '',
              icon: Icons.warning,
              leadingIcon: Icons.warning,
              leadingIconColor: TicketHelper.getPriorityColor(_selectedImpact),
              options: _impactOptions,
              onChanged: (value) => setState(() => _selectedImpact = value),
              validator: (value) =>
              value == null ? 'Vui lòng chọn tầm quan trọng' : null,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TicketHelper.getPriorityColor(_selectedPriority)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TicketHelper.getPriorityColor(_selectedPriority)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: TicketHelper.getPriorityColor(_selectedPriority),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mức ưu tiên: ${_priorityOptions[_selectedPriority]}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: TicketHelper.getPriorityColor(_selectedPriority),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFFFEE2E2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isCreating ? null : _createTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isCreating
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.add_task, size: 24),
        label: Text(
          _isCreating ? 'Đang tạo ticket...' : 'Tạo ticket',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }



  Widget _buildStyledDropdown({
    required String value,
    required Map<String, String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
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
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textSecondary,
      ),
      items: items.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: TicketHelper.getPriorityColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Vui lòng chọn $label' : null,
    );
  }
}
