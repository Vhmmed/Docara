import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/core/services/unread_count_cubit.dart';

class GlassNavItem {
  final IconData icon;
  final String label;
  final Widget screen;

  const GlassNavItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class GlassNavShell extends StatefulWidget {
  static const double navBarOverlap = 108;

  final List<GlassNavItem> items;
  final Color? accentColor;
  final int? messagesTabIndex;

  const GlassNavShell({
    super.key,
    required this.items,
    this.accentColor,
    this.messagesTabIndex,
  });

  @override
  State<GlassNavShell> createState() => _GlassNavShellState();
}

class _GlassNavShellState extends State<GlassNavShell> {
  late final PageController _pageController;
  int _currentScreen = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentScreen);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isNarrow => widget.items.length >= 5;

  Color _accentColor() {
    return widget.accentColor ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final keyboardVisible = keyboardHeight > 50;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: widget.items.map((item) => item.screen).toList(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: keyboardVisible ? -150 : 20,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: keyboardVisible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: keyboardVisible ? 0 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          widget.items.length,
                          (index) {
                            final navItem = _buildNavItem(index, accent);
                            if (_isNarrow) {
                              return Expanded(child: navItem);
                            }
                            return navItem;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, Color accent) {
    final item = widget.items[index];
    final isSelected = _currentScreen == index;
    final isMessagesTab = widget.messagesTabIndex != null && index == widget.messagesTabIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _currentScreen = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: _isNarrow ? 4 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isMessagesTab
                ? BlocBuilder<UnreadCountCubit, int>(
                    bloc: sl<UnreadCountCubit>(),
                    builder: (_, count) => _buildIconWithBadge(
                      icon: item.icon,
                      isSelected: isSelected,
                      count: count,
                    ),
                  )
                : Icon(
                    item.icon,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
            if (isSelected) ...[
              SizedBox(width: _isNarrow ? 4 : 6),
              if (_isNarrow)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required bool isSelected,
    required int count,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 14),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
