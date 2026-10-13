import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';
import '../../features/loans/presentation/screens/loan_list_screen.dart';
import '../../features/members/presentation/screens/member_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../widgets/placeholder_tab_screen.dart';

/// Item representing a tab in the [MainShell].
class ShellTabItem {
  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final Widget screen;

  const ShellTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}

/// Main application navigation shell with a synchronized [NavigationBar] and [PageView].
/// Supports role-based tabs (Librarian vs Member), swipe navigation, keep-alive, and back-to-Home handling.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ShellTabItem> _buildTabs(bool isLibrarian) {
    if (isLibrarian) {
      return const [
        ShellTabItem(
          label: 'Home',
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          screen: HomeScreen(),
        ),
        ShellTabItem(
          label: 'Books',
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          screen: BookListScreen(),
        ),
        ShellTabItem(
          label: 'Members',
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          screen: MemberListScreen(),
        ),
        ShellTabItem(
          label: 'Loans',
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          screen: LoanListScreen(),
        ),
        ShellTabItem(
          label: 'Settings',
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          screen: SettingsScreen(),
        ),
      ];
    } else {
      return const [
        ShellTabItem(
          label: 'Home',
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          screen: HomeScreen(),
        ),
        ShellTabItem(
          label: 'My Loans',
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          screen: LoanListScreen(
            isReadOnly: true,
            title: 'My Loans',
          ),
        ),
        ShellTabItem(
          label: 'Browse',
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          screen: BookListScreen(),
        ),
        ShellTabItem(
          label: 'Settings',
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          screen: SettingsScreen(),
        ),
      ];
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isLibrarian = authController.user?.isLibrarian ?? false;
    final tabs = _buildTabs(isLibrarian);

    // Ensure index stays in valid range when role switches
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          _onDestinationSelected(0);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: tabs.map((tab) => tab.screen).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: tabs
              .map(
                (tab) => NavigationDestination(
                  icon: tab.icon,
                  selectedIcon: tab.selectedIcon,
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

