import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Breakpoints
/// Mobile  : width < 600
/// Tablet  : 600 ≤ width < 960
/// Desktop : width ≥ 960
class Responsive {
  static const double _mobile  = 600;
  static const double _tablet  = 960;
  static const double _maxContent = 1200;
  static const double maxListCard = 940;
  static const double maxForm     = 640;
  static const double sidebarWidth = 210;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context)  => width(context) < _mobile;
  static bool isTablet(BuildContext context)  =>
      width(context) >= _mobile && width(context) < _tablet;
  static bool isDesktop(BuildContext context) => width(context) >= _tablet;
  /// Alias used in app_shell — same as isDesktop.
  static bool isWide(BuildContext context)    => width(context) >= _tablet;

  static T value<T>(BuildContext context, {
    required T mobile, T? tablet, required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context))  return tablet ?? desktop;
    return mobile;
  }

  /// Page-level horizontal padding.
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
    vertical: 16,
  );

  /// Centers and constrains content width.
  static Widget constrain(Widget child, {double max = _maxContent}) =>
      Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child));

  /// KPI / stat card grid columns.
  static int kpiColumns(BuildContext context) =>
      value(context, mobile: 2, tablet: 3, desktop: 4);

  /// Vehicle / trip card grid columns.
  static int cardColumns(BuildContext context) =>
      value(context, mobile: 1, tablet: 2, desktop: 2);
}

// ── Reusable responsive list body ──────────────────────────────────────────

/// Wraps a list of pre-built cards in a RefreshIndicator, constrains width,
/// and optionally lays them out in a 2-column grid on wider screens.
class RListBody extends StatelessWidget {
  final List<Widget>          cards;
  final Future<void> Function() onRefresh;
  final double  maxWidth;
  final bool    twoColumn;   // 2-col grid on screens ≥ 720 px content width
  final EdgeInsets? padding;

  const RListBody({
    super.key,
    required this.cards,
    required this.onRefresh,
    this.maxWidth = Responsive.maxListCard,
    this.twoColumn = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final p = padding ?? Responsive.pagePadding(context);
    return LayoutBuilder(builder: (ctx, constraints) {
      final useGrid = twoColumn && constraints.maxWidth >= 720;
      final body = useGrid ? _TwoColCards(cards: cards) : _OneColCards(cards: cards);
      return RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Padding(padding: p, child: body),
            ),
          ),
        ),
      );
    });
  }
}

class _OneColCards extends StatelessWidget {
  final List<Widget> cards;
  const _OneColCards({required this.cards});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards);
}

class _TwoColCards extends StatelessWidget {
  final List<Widget> cards;
  const _TwoColCards({required this.cards});
  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox();
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[i]),
          const SizedBox(width: 14),
          i + 1 < cards.length
            ? Expanded(child: cards[i + 1])
            : const Expanded(child: SizedBox()),
        ],
      ));
    }
    return Column(children: rows);
  }
}

// ── Responsive scaffold for non-AppShell pages (forms, previews) ───────────

/// Centres and constrains a scrollable form / detail page.
class RFormPage extends StatelessWidget {
  final Widget       child;
  final double       maxWidth;
  final EdgeInsets?  padding;
  final ScrollController? controller;

  const RFormPage({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxForm,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final p = padding ?? Responsive.pagePadding(context);
    return SingleChildScrollView(
      controller: controller,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: p, child: child),
        ),
      ),
    );
  }
}
