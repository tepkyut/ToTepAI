import 'package:flutter/material.dart';

/// Centralized breakpoints and helpers for responsive layouts.
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < AppBreakpoints.tablet;
  bool get isTablet =>
      screenWidth >= AppBreakpoints.tablet && screenWidth < AppBreakpoints.desktop;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  /// Returns padding that scales with screen width.
  EdgeInsets get responsivePagePadding {
    if (isDesktop) return const EdgeInsets.symmetric(horizontal: 100, vertical: 32);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  }

  /// Constrains content width for large displays while keeping mobile full width.
  double get responsiveMaxWidth {
    if (isDesktop) return 1000;
    if (isTablet) return 700;
    return double.infinity;
  }
}

/// Widget helper to center content with a max width on large screens.
class ResponsiveConstrainedBox extends StatelessWidget {
  const ResponsiveConstrainedBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.responsiveMaxWidth),
        child: child,
      ),
    );
  }
}
