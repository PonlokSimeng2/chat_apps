import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// A helper class to manage responsive design across the app
class ResponsiveHelper {
  const ResponsiveHelper._();

  /// Get responsive breakpoint values
  static bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isMobile;

  static bool isTablet(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isTablet;

  static bool isDesktop(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isDesktop;

  static bool isLargerThanDesktop(BuildContext context) =>
      ResponsiveBreakpoints.of(context).largerThan(DESKTOP);

  static bool isSmallerThanTablet(BuildContext context) =>
      ResponsiveBreakpoints.of(context).smallerThan(TABLET);

  /// Screen size information
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Responsive spacing
  static double getPadding(BuildContext context) {
    if (isDesktop(context)) return 24.0;
    if (isTablet(context)) return 20.0;
    return 16.0;
  }

  static double getSmallPadding(BuildContext context) {
    if (isDesktop(context)) return 20.0;
    if (isTablet(context)) return 18.0;
    return 12.0;
  }

  static double getLargePadding(BuildContext context) {
    if (isDesktop(context)) return 32.0;
    if (isTablet(context)) return 24.0;
    return 20.0;
  }

  /// Responsive margins
  static double getMargin(BuildContext context) {
    if (isDesktop(context)) return 16.0;
    if (isTablet(context)) return 12.0;
    return 8.0;
  }

  /// Responsive border radius
  static double getBorderRadius(BuildContext context) {
    if (isDesktop(context)) return 16.0;
    if (isTablet(context)) return 14.0;
    return 12.0;
  }

  static double getSmallBorderRadius(BuildContext context) {
    if (isDesktop(context)) return 12.0;
    if (isTablet(context)) return 10.0;
    return 8.0;
  }

  /// Responsive font sizes
  static double getHeadingFontSize(BuildContext context) {
    if (isDesktop(context)) return 28.0;
    if (isTablet(context)) return 24.0;
    return 20.0;
  }

  static double getTitleFontSize(BuildContext context) {
    if (isDesktop(context)) return 18.0;
    if (isTablet(context)) return 17.0;
    return 16.0;
  }

  static double getSubtitleFontSize(BuildContext context) {
    if (isDesktop(context)) return 16.0;
    if (isTablet(context)) return 15.0;
    return 14.0;
  }

  static double getBodyFontSize(BuildContext context) {
    if (isDesktop(context)) return 14.0;
    if (isTablet(context)) return 13.0;
    return 12.0;
  }

  static double getCaptionFontSize(BuildContext context) {
    if (isDesktop(context)) return 12.0;
    if (isTablet(context)) return 11.0;
    return 10.0;
  }

  /// Responsive icon sizes
  static double getIconSize(BuildContext context) {
    if (isDesktop(context)) return 28.0;
    if (isTablet(context)) return 26.0;
    return 24.0;
  }

  static double getSmallIconSize(BuildContext context) {
    if (isDesktop(context)) return 20.0;
    if (isTablet(context)) return 18.0;
    return 16.0;
  }

  static double getLargeIconSize(BuildContext context) {
    if (isDesktop(context)) return 32.0;
    if (isTablet(context)) return 30.0;
    return 28.0;
  }

  /// Responsive avatar sizes
  static double getAvatarSize(BuildContext context) {
    if (isDesktop(context)) return 64.0;
    if (isTablet(context)) return 60.0;
    return 52.0;
  }

  static double getSmallAvatarSize(BuildContext context) {
    if (isDesktop(context)) return 56.0;
    if (isTablet(context)) return 48.0;
    return 40.0;
  }

  static double getLargeAvatarSize(BuildContext context) {
    if (isDesktop(context)) return 72.0;
    if (isTablet(context)) return 68.0;
    return 60.0;
  }

  /// Responsive component heights
  static double getAppBarHeight(BuildContext context) {
    if (isDesktop(context)) return 80.0;
    if (isTablet(context)) return 70.0;
    return 60.0;
  }

  static double getSearchBarHeight(BuildContext context) {
    if (isDesktop(context)) return 60.0;
    if (isTablet(context)) return 54.0;
    return 44.0;
  }

  static double getButtonHeight(BuildContext context) {
    if (isDesktop(context)) return 56.0;
    if (isTablet(context)) return 52.0;
    return 48.0;
  }

  static double getSmallButtonHeight(BuildContext context) {
    if (isDesktop(context)) return 44.0;
    if (isTablet(context)) return 40.0;
    return 36.0;
  }

  /// Responsive text field heights
  static double getTextFieldHeight(BuildContext context) {
    if (isDesktop(context)) return 60.0;
    if (isTablet(context)) return 56.0;
    return 48.0;
  }

  static double getSmallTextFieldHeight(BuildContext context) {
    if (isDesktop(context)) return 48.0;
    if (isTablet(context)) return 44.0;
    return 40.0;
  }

  /// Responsive list tile dimensions
  static double getListTileHeight(BuildContext context) {
    if (isDesktop(context)) return 90.0;
    if (isTablet(context)) return 80.0;
    return 70.0;
  }

  static double getListTilePadding(BuildContext context) {
    if (isDesktop(context)) return 20.0;
    if (isTablet(context)) return 18.0;
    return 16.0;
  }

  static double getListTileVerticalPadding(BuildContext context) {
    if (isDesktop(context)) return 16.0;
    if (isTablet(context)) return 14.0;
    return 12.0;
  }

  /// Responsive navigation
  static bool shouldUseNavigationRail(BuildContext context) =>
      isDesktop(context);

  static double getNavigationRailWidth(BuildContext context) {
    if (isDesktop(context)) return 300.0;
    return 200.0;
  }

  /// Responsive layout column count
  static int getCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static int getGalleryCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 6;
    if (isTablet(context)) return 4;
    return 3;
  }

  /// Responsive breakpoints information
  static String getBreakpointName(BuildContext context) {
    if (isDesktop(context)) return 'Desktop';
    if (isTablet(context)) return 'Tablet';
    return 'Mobile';
  }

  static String getBreakpointEmoji(BuildContext context) {
    if (isDesktop(context)) return '🖥️';
    if (isTablet(context)) return '📱';
    return '📱';
  }

  /// Responsive visibility widgets
  static Widget showOnDesktop(Widget child, BuildContext context) {
    return isDesktop(context) ? child : const SizedBox.shrink();
  }

  static Widget showOnTablet(Widget child, BuildContext context) {
    return isTablet(context) ? child : const SizedBox.shrink();
  }

  static Widget showOnMobile(Widget child, BuildContext context) {
    return isMobile(context) ? child : const SizedBox.shrink();
  }

  static Widget hideOnDesktop(Widget child, BuildContext context) {
    return isDesktop(context) ? const SizedBox.shrink() : child;
  }

  /// Debug information (only shown in debug mode)
  static Widget debugBreakpointIndicator(BuildContext context) {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final breakpointName = ResponsiveHelper.getBreakpointName(context);
    final emoji = ResponsiveHelper.getBreakpointEmoji(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: ResponsiveHelper.getSmallPadding(context),
      ),
      color: isMobile
          ? Colors.red.withValues(alpha: 0.3)
          : isTablet
          ? Colors.orange.withValues(alpha: 0.3)
          : Colors.transparent,
      child: Text(
        '$emoji $breakpointName MODE',
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveHelper.getCaptionFontSize(context),
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Responsive text scaling for better accessibility
  static double getResponsiveScale(BuildContext context) {
    final screenWidth = ResponsiveHelper.screenWidth(context);
    if (screenWidth > 1200) return 1.1;
    if (screenWidth > 800) return 1.05;
    return 1.0;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device has notched display
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 24; // Typical notch height
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    ResponsiveHelper.screenWidth(context);
    final maxWidth = isDesktop(context)
        ? 1200.0
        : isTablet(context)
        ? 800.0
        : double.infinity;

    return BoxConstraints(
      maxWidth: maxWidth,
      minWidth: 0,
      maxHeight: double.infinity,
    );
  }
}
