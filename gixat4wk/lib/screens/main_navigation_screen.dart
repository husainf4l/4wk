import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/screens/clients/clients_screen.dart';
import 'package:gixat4wk/screens/job_order/job_orders_screen.dart';
import '../controllers/navigation_controller.dart';
import 'sessions/sessions_screen.dart';
import '../screens/add_client_screen.dart';
import '../screens/profile_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the navigation controller
    final NavigationController navController = Get.put(NavigationController());
    final theme = Theme.of(context);

    // List of screens to be shown in the tab view
    final List<Widget> screens = [
      const JobOrdersScreen(),
      const SessionsScreen(),
      const ClientsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: navController.currentIndex.value,
          children: screens,
        ),
      ),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: BoxDecoration(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border(
              top: BorderSide(
                color:
                    theme.brightness == Brightness.dark
                        ? Colors.grey[900]!
                        : Colors.grey[200]!,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.align_vertical_center_outlined,
                    activeIcon: Icons.align_vertical_center,
                    index: 0,
                    currentIndex: navController.currentIndex.value,
                    onTap: () => navController.changeTab(0),
                    hasBadge: true,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.work_outline,
                    activeIcon: Icons.work,
                    index: 1,
                    currentIndex: navController.currentIndex.value,
                    onTap: () => navController.changeTab(1),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.add_outlined,
                    activeIcon: Icons.add,
                    index: -1, // Special index to indicate it's not a tab
                    currentIndex: navController.currentIndex.value,
                    onTap: () => Get.to(() => const AddClientScreen()),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    index: 2,
                    currentIndex: navController.currentIndex.value,
                    onTap: () => navController.changeTab(2),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    index: 3,
                    currentIndex: navController.currentIndex.value,
                    onTap: () => navController.changeTab(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    String? label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = currentIndex == index;
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor =
        theme.brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[700];

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryColor.withAlpha(26)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? primaryColor : unselectedColor,
                  size: 24,
                ),
              ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : unselectedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
