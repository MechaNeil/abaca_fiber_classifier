import 'package:flutter/material.dart';
import '../viewmodels/theme_view_model.dart';

/// A beautiful animated toggle widget that switches between sun and moon icons
/// with smooth transitions for an excellent user experience
class AnimatedThemeToggle extends StatefulWidget {
  final ThemeViewModel themeViewModel;
  final double size;
  final Duration animationDuration;
  final VoidCallback? onToggle;

  const AnimatedThemeToggle({
    super.key,
    required this.themeViewModel,
    this.size = 28.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onToggle,
  });

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _colorController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(
        milliseconds: widget.animationDuration.inMilliseconds ~/ 2,
      ),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Initialize animations
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _colorAnimation =
        ColorTween(
          begin: Colors.orange, // Sun color
          end: Colors.indigo.shade300, // Moon color
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    // Set initial animation state based on current theme
    if (widget.themeViewModel.isDarkMode) {
      _rotationController.value = 1.0;
      _colorController.value = 1.0;
    }

    // Listen to theme changes
    widget.themeViewModel.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeViewModel.removeListener(_onThemeChanged);
    _rotationController.dispose();
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      _animateToCurrentTheme();
    }
  }

  void _animateToCurrentTheme() {
    if (widget.themeViewModel.isDarkMode) {
      _rotationController.forward();
      _colorController.forward();
    } else {
      _rotationController.reverse();
      _colorController.reverse();
    }
  }

  Future<void> _handleToggle() async {
    // Trigger scale animation for feedback
    await _scaleController.forward();
    _scaleController.reverse();

    // Toggle theme
    await widget.themeViewModel.toggleTheme();

    // Call optional callback
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleToggle,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _scaleAnimation,
          _colorAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159, // Full rotation
              child: Center(
                child: AnimatedSwitcher(
                  duration: widget.animationDuration,
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    widget.themeViewModel.isDarkMode
                        ? Icons.nights_stay
                        : Icons.wb_sunny,
                    key: ValueKey(widget.themeViewModel.isDarkMode),
                    size: widget.size * 1.2,
                    color: _colorAnimation.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A simpler version of the theme toggle for use in tight spaces
class CompactThemeToggle extends StatelessWidget {
  final ThemeViewModel themeViewModel;
  final double size;

  const CompactThemeToggle({
    super.key,
    required this.themeViewModel,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => themeViewModel.toggleTheme(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          themeViewModel.isDarkMode
              ? Icons.nights_stay_outlined
              : Icons.wb_sunny_outlined,
          key: ValueKey(themeViewModel.isDarkMode),
          size: size,
          color: themeViewModel.isDarkMode
              ? Colors.indigo.shade300
              : Colors.orange,
        ),
      ),
      tooltip: themeViewModel.isDarkMode
          ? 'Switch to Light Mode'
          : 'Switch to Dark Mode',
    );
  }
}

/// A themed toggle button with text labels
class ThemedToggleButton extends StatelessWidget {
  final ThemeViewModel themeViewModel;
  final bool showLabels;

  const ThemedToggleButton({
    super.key,
    required this.themeViewModel,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            context,
            isSelected: themeViewModel.isLightMode,
            icon: Icons.wb_sunny_outlined,
            label: showLabels ? 'Light' : null,
            onTap: () => themeViewModel.setThemeMode(
              themeViewModel.currentThemeMode == themeViewModel.currentThemeMode
                  ? themeViewModel.currentThemeMode
                  : themeViewModel.currentThemeMode,
            ),
          ),
          _buildToggleOption(
            context,
            isSelected: themeViewModel.isDarkMode,
            icon: Icons.nights_stay_outlined,
            label: showLabels ? 'Dark' : null,
            onTap: () => themeViewModel.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required bool isSelected,
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
            ),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
