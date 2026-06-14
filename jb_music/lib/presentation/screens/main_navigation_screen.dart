// lib/presentation/screens/main_navigation_screen.dart
//
// JB MUSIC — NOVA NAVIGATION
// ─────────────────────────────────────────────────────────────────────────────
// Floating glass nav bar + liquid indicator + premium mini player
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/presentation/widgets/mini_player_bar.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'jb_assistant_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _voiceStarted = false;
  late final AnimationController _navCtrl;

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
    _navCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_voiceStarted) {
        _voiceStarted = true;
        context.read<MusicBloc>().add(StartVoiceListeningEvent());
      }
    });
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JBColors.void0,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          _NovaNavBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              if (i != _currentIndex) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = i);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOVA NAV BAR
// ─────────────────────────────────────────────────────────────────────────────
class _NovaNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NovaNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,          label: 'Home'),
      _NavItem(icon: Icons.library_music_outlined, activeIcon: Icons.library_music_rounded, label: 'Library'),
      _NavItem(icon: Icons.search_outlined,        activeIcon: Icons.search_rounded,        label: 'Search'),
      _NavItem(icon: Icons.auto_awesome_outlined,  activeIcon: Icons.auto_awesome_rounded,  label: 'JB AI'),
      _NavItem(icon: Icons.tune_outlined,          activeIcon: Icons.tune_rounded,          label: 'Settings'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: JBColors.void2.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: JBColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                children: items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final active = i == currentIndex;
                  final isJB = i == 3;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon container
                          AnimatedContainer(
                            duration: 250.ms,
                            curve: JBAnim.spring,
                            width: isJB ? (active ? 46 : 38) : 34,
                            height: isJB ? (active ? 46 : 38) : 34,
                            decoration: isJB
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: active ? JBGradients.nova : null,
                                    color: active ? null : JBColors.glass10,
                                    border: Border.all(
                                      color: active
                                          ? Colors.transparent
                                          : JBColors.glassBorder,
                                      width: 0.8,
                                    ),
                                    boxShadow: active ? JBShadow.nova : null,
                                  )
                                : BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: active ? JBColors.novaFaint : Colors.transparent,
                                  ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: 200.ms,
                                transitionBuilder: (child, anim) => ScaleTransition(
                                  scale: Tween(begin: 0.7, end: 1.0).animate(
                                    CurvedAnimation(parent: anim, curve: JBAnim.spring),
                                  ),
                                  child: child,
                                ),
                                child: Icon(
                                  active ? item.activeIcon : item.icon,
                                  key: ValueKey(active),
                                  color: active
                                      ? (isJB ? Colors.white : JBColors.nova)
                                      : JBColors.textTertiary,
                                  size: isJB ? (active ? 22 : 20) : 20,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 3),

                          // Label
                          AnimatedDefaultTextStyle(
                            duration: 200.ms,
                            style: JBType.micro.copyWith(
                              color: active
                                  ? (isJB ? JBColors.nova : JBColors.nova)
                                  : JBColors.textTertiary,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 10,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
