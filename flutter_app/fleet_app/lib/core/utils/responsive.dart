import 'package:flutter/material.dart';

/// Breakpoints
/// Mobile  : width < 600
/// Tablet  : 600 <= width < 960
/// Desktop : width >= 960

class Responsive {
  static const double _mobile  = 600;
  static const double _tablet  = 960;
  static const double _maxContent = 1280; // max content width on very wide screens

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context)  => width(context) < _mobile;
  static bool isTablet(BuildContext context)  => width(context) >= _mobile && width(context) < _tablet;
  static bool isDesktop(BuildContext context) => width(context) >= _tablet;

  /// Returns a value based on screen size.
  static T value<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context))  return tablet ?? desktop;
    return mobile;
  }

  /// Responsive horizontal padding.
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: value(context, mobile: 16, tablet: 24, desktop: 32),
    vertical:   16,
  );

  /// Constrain content width on large screens and centre it.
  static Widget constrain(Widget child, {double max = _maxContent}) =>
      Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ));

  /// Number of grid columns for stat/KPI cards.
  static int kpiColumns(BuildContext context) =>
      value(context, mobile: 2, tablet: 3, desktop: 4);

  /// Number of grid columns for vehicle/trip cards.
  static int cardColumns(BuildContext context) =>
      value(context, mobile: 1, tablet: 2, desktop: 3);
}
