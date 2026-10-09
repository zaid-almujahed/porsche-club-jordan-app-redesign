import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_feedback.dart';
import 'package:pcj_v5/shared/widgets/app_motion.dart';

class AppPageBody extends StatelessWidget {
  const AppPageBody({
    super.key,
    required this.child,
    this.topPadding = AppSpacing.xl,
    this.bottomPadding = AppSpacing.pageBottom,
    this.onRefresh,
  });

  final Widget child;
  final double topPadding;
  final double bottomPadding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalPadding = AppLayout.horizontalPadding(
          constraints.maxWidth,
        );
        // The page's controls float over the content (PorscheAppBar), which
        // starts below them and scrolls under them.
        final double topInset = MediaQuery.paddingOf(context).top;

        final Widget scrollView = CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: onRefresh == null
              ? null
              : const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            // Holds the controls' place, so content brought into view (a
            // focused field, ensureVisible) stops below them.
            if (topInset > 0)
              SliverPersistentHeader(
                pinned: true,
                delegate: _FloatingControlsSpace(topInset),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxContentWidth,
                    ),
                    // Scroll views inside must not add the inset again.
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        if (onRefresh == null) return scrollView;
        return RefreshIndicator(
          color: AppColors.primaryBright,
          backgroundColor: AppColors.surfaceRaised,
          displacement: 24,
          edgeOffset: AppSpacing.xs + topInset,
          elevation: 0,
          strokeWidth: 2.4,
          onRefresh: onRefresh!,
          child: scrollView,
        );
      },
    );
  }
}

/// An empty, see-through pinned header the height of the controls floating
/// over the page.
class _FloatingControlsSpace extends SliverPersistentHeaderDelegate {
  const _FloatingControlsSpace(this.extent);

  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => const SizedBox.expand();

  @override
  bool shouldRebuild(_FloatingControlsSpace oldDelegate) =>
      oldDelegate.extent != extent;
}

class GradientPanel extends StatelessWidget {
  const GradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = AppRadii.medium,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppDecorations.panel(radius: radius),
      child: child,
    );
  }
}

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'Nothing is currently available.',
  });

  final AsyncState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return AppMotion.switcherLayout(
          currentChild,
          previousChildren,
          alignment: Alignment.topCenter,
        );
      },
      child: _buildState(context),
    );
  }

  Widget _buildState(BuildContext context) {
    final T? data = state.data;

    if (state.isLoading && data == null) {
      return const Padding(
        key: ValueKey<String>('async-loading'),
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: AppLoadingIndicator()),
      );
    }

    if (state.hasError && data == null) {
      return AppErrorState(
        key: const ValueKey<String>('async-error'),
        message: readableError(state.error!),
        onRetry: onRetry,
      );
    }

    if (data == null) {
      return const SizedBox.shrink(key: ValueKey<String>('async-none'));
    }

    if (isEmpty?.call(data) ?? false) {
      return AppEmptyState(
        key: const ValueKey<String>('async-empty'),
        message: emptyMessage,
      );
    }

    // Pull-to-refresh already supplies progress feedback. Keeping the current
    // content in place avoids the generic full-width loading bar flashing over
    // every refreshed section.
    return KeyedSubtree(
      key: const ValueKey<String>('async-data'),
      child: builder(context, data),
    );
  }
}
