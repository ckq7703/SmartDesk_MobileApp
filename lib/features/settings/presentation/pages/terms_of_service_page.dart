import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Điều khoản sử dụng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điều khoản sử dụng',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Có hiệu lực từ: 01/10/2025',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Chấp nhận điều khoản',
              content:
              'Bằng việc truy cập và sử dụng ứng dụng SmartDesk Mobile, bạn đồng ý tuân thủ các điều khoản và điều kiện sau đây. Nếu không đồng ý, vui lòng không sử dụng dịch vụ của chúng tôi.',
            ),
            _buildSection(
              title: '2. Tài khoản người dùng',
              content:
              'Để sử dụng dịch vụ, bạn cần:\n\n'
                  '• Cung cấp thông tin chính xác và đầy đủ\n'
                  '• Bảo mật thông tin đăng nhập\n'
                  '• Thông báo ngay khi phát hiện sử dụng trái phép\n'
                  '• Chịu trách nhiệm về mọi hoạt động từ tài khoản của bạn',
            ),
            _buildSection(
              title: '3. Quyền và nghĩa vụ của người dùng',
              content:
              'Người dùng có quyền:\n\n'
                  '• Sử dụng dịch vụ theo quy định\n'
                  '• Được hỗ trợ kỹ thuật\n'
                  '• Bảo vệ dữ liệu cá nhân\n\n'
                  'Người dùng có nghĩa vụ:\n\n'
                  '• Không sử dụng dịch vụ cho mục đích bất hợp pháp\n'
                  '• Không can thiệp vào hệ thống\n'
                  '• Tuân thủ các quy định về sử dụng',
            ),
            _buildSection(
              title: '4. Nội dung và sở hữu trí tuệ',
              content:
              'Tất cả nội dung, thiết kế, logo, thương hiệu trong ứng dụng thuộc quyền sở hữu của SmartDesk. Người dùng không được sao chép, phân phối hoặc sử dụng cho mục đích thương mại khi chưa được cho phép.',
            ),
            _buildSection(
              title: '5. Giới hạn trách nhiệm',
              content:
              'SmartDesk không chịu trách nhiệm cho:\n\n'
                  '• Sự gián đoạn dịch vụ do lỗi kỹ thuật\n'
                  '• Mất mát dữ liệu không thuộc lỗi của chúng tôi\n'
                  '• Thiệt hại gián tiếp từ việc sử dụng dịch vụ\n'
                  '• Hành vi của bên thứ ba',
            ),
            _buildSection(
              title: '6. Chấm dứt dịch vụ',
              content:
              'Chúng tôi có quyền tạm ngưng hoặc chấm dứt tài khoản của bạn nếu:\n\n'
                  '• Vi phạm điều khoản sử dụng\n'
                  '• Có hành vi gian lận\n'
                  '• Yêu cầu của cơ quan pháp luật\n'
                  '• Theo yêu cầu của người dùng',
            ),
            _buildSection(
              title: '7. Thay đổi điều khoản',
              content:
              'SmartDesk có quyền thay đổi điều khoản sử dụng bất cứ lúc nào. Chúng tôi sẽ thông báo về các thay đổi quan trọng qua email hoặc thông báo trong ứng dụng.',
            ),
            _buildSection(
              title: '8. Luật áp dụng',
              content:
              'Điều khoản này được điều chỉnh bởi pháp luật Việt Nam. Mọi tranh chấp phát sinh sẽ được giải quyết tại Tòa án có thẩm quyền.',
            ),
            _buildSection(
              title: '9. Liên hệ',
              content:
              'Nếu có thắc mắc về điều khoản, vui lòng liên hệ:\n\n'
                  'Email: support@smartpro.vn\n'
                  'Điện thoại: (028) 39 306 767\n'
                  'Địa chỉ: Lầu 6, toà nhà Thiên Sơn, 5-7-9 Nguyễn Gia Thiều, P. Xuân Hòa, TP. HCM',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bằng việc tiếp tục sử dụng, bạn đã đồng ý với các điều khoản trên.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
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

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
