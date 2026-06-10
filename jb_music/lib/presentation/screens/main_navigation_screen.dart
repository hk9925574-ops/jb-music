// lib/presentation/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/presentation/widgets/mini_player_bar.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'jb_assistant_screen.dart';
import 'settings_screen.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    LibraryScreen(),
    SearchScreen(),
    JBAssistantScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MusicBloc>().add(StartVoiceListeningEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          _JBNavBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ],
      ),
    );
  }
}

class _JBNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _JBNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home,           label: 'Home'),
      _NavItem(icon: Icons.library_music_outlined, activeIcon: Icons.library_music, label: 'Library'),
      _NavItem(icon: Icons.search_outlined,      activeIcon: Icons.search,         label: 'Search'),
      _NavItem(icon: Icons.mic_none_outlined,    activeIcon: Icons.mic,            label: 'JB'),
      _NavItem(icon: Icons.settings_outlined,    activeIcon: Icons.settings,       label: 'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final item    = items[i];
              final active  = i == currentIndex;
              final isJB    = i == 3; // JB Assistant — special gold treatment
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isJB && active ? 42 : 28,
                        height: isJB && active ? 42 : 28,
                        decoration: isJB && active
                            ? const BoxDecoration(
                                color: RG.gold,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Center(
                          child: Icon(
                            active ? item.activeIcon : item.icon,
                            color: active
                                ? (isJB ? Colors.black : Colors.white)
                                : Colors.white38,
                            size: isJB ? (active ? 22 : 24) : 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white38,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}