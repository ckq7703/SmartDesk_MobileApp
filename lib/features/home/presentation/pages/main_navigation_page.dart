import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../tickets/presentation/pages/home_page.dart';
import '../../../tickets/presentation/pages/ticket_list_page.dart';
import '../pages/faq_page.dart';
// import '../pages/notifications_page1.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

import '../pages/settings_page.dart';

class MainNavigationPage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const MainNavigationPage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,

  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 2; // Default: Trang Chủ

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TicketListPage(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
      FaqPage(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
      HomePage(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
      NotificationsPage(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,
      ),
      SettingsPage(
        baseUrl: widget.baseUrl,
        sessionToken: widget.sessionToken,

      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.confirmation_number_outlined,
                  selectedIcon: Icons.confirmation_number,
                  label: 'Ticket',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.help_outline,
                  selectedIcon: Icons.help,
                  label: 'FAQ',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Trang Chủ',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications_outlined,
                  selectedIcon: Icons.notifications,
                  label: 'Thông báo',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Cài đặt',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textHint,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
