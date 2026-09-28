import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_feedback.dart';
import 'package:pcj_v5/shared/widgets/app_motion.dart';

export 'package:pcj_v5/shared/widgets/app_feedback.dart';
export 'package:pcj_v5/shared/widgets/app_motion.dart';

enum AppSection { home, events, shop, offers, profile }

class PorscheAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PorscheAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showNotifications = false,
    this.showCart = false,
    this.showClose = false,
    this.showEdit = false,
    this.onBack,
    this.onNotificationsPressed,
    this.onCartPressed,
    this.onClose,
    this.onEdit,
    this.unreadNotificationCount,
    this.closeTooltip = 'Cancel registration',
    this.cartItemCount,
  });

  final String title;
  final bool showBack;
  final bool showNotifications;
  final bool showCart;
  final bool showClose;
  final bool showEdit;
  final VoidCallback? onBack;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCartPressed;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final ValueListenable<int>? unreadNotificationCount;
  final String closeTooltip;

  /// Drives the item-count badge on the cart button.
  final ValueListenable<int>? cartItemCount;

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    // System back follows the same rule as the on-screen back button.
    return AppBackScope(
      enabled: showBack,
      onBack: onBack,
      child: _buildAppBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.appBar,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      leadingWidth: 68,
      leading: showBack
          ? AppBarButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              // Pops when there is history; otherwise (redirected or `go`
              // routes) goes to the page's parent instead of doing nothing.
              onPressed: onBack ?? () => context.goBack(),
              leading: true,
            )
          : showCart
          ? _CartButton(
              onPressed: onCartPressed ?? () {},
              itemCount: cartItemCount,
              leading: true,
            )
          : null,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(title.toUpperCase(), style: AppTextStyles.appBarTitle),
      ),
      actions: <Widget>[
        // With a back button in the leading slot, the cart moves to the right.
        if (showCart && showBack)
          _CartButton(
            onPressed: onCartPressed ?? () {},
            itemCount: cartItemCount,
            leading: false,
          ),
        if (showNotifications)
          _NotificationButton(
            onPressed: onNotificationsPressed ?? () {},
            unreadCount: unreadNotificationCount,
          ),
        if (showClose)
          AppBarButton(
            icon: Icons.close_rounded,
            tooltip: closeTooltip,
            onPressed: onClose,
          ),
        if (showEdit)
          AppBarButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit application',
            onPressed: onEdit,
          ),
        if (showNotifications ||
            showClose ||
            showEdit ||
            (showCart && showBack))
          const SizedBox(width: AppSpacing.sm),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        // Hairline with a faint red glow at its centre.
        child: Container(
          height: 1.0,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.border,
                Color(0x8CD5001C),
                AppColors.border,
              ],
              stops: <double>[0.1, 0.5, 0.9],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onPressed,
    required this.unreadCount,
  });

  final VoidCallback onPressed;
  final ValueListenable<int>? unreadCount;

  @override
  Widget build(BuildContext context) {
    final ValueListenable<int>? count = unreadCount;
    if (count == null) return _buildButton(0);
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (BuildContext context, int value, Widget? child) {
        return _buildButton(value);
      },
    );
  }

  Widget _buildButton(int unreadCount) {
    final bool hasUnread = unreadCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        AppBarButton(
          icon: Icons.notifications_none_rounded,
          tooltip: hasUnread
              ? 'Notifications, $unreadCount unread'
              : 'Notifications',
          onPressed: onPressed,
        ),
        Positioned(
          top: 14,
          right: 8,
          child: AnimatedScale(
            scale: hasUnread ? 1 : 0,
            duration: AppMotion.medium,
            curve: Curves.easeOutBack,
            child: Container(
              key: const ValueKey<String>('unread-notifications-dot'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.primaryBright,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.appBar, width: 1.5),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: AppColors.primaryGlow, blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Round cart button with a live item-count badge.
class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.onPressed,
    required this.itemCount,
    required this.leading,
  });

  final VoidCallback onPressed;
  final ValueListenable<int>? itemCount;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final ValueListenable<int>? count = itemCount;
    if (count == null) return _buildButton(0);
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (BuildContext context, int value, Widget? child) {
        return _buildButton(value);
      },
    );
  }

  Widget _buildButton(int count) {
    final bool hasItems = count > 0;
    return Padding(
      padding: EdgeInsets.only(
        left: leading ? AppSpacing.md : 0,
        right: leading ? 0 : AppSpacing.xs,
      ),
      child: Center(
        child: SizedBox.square(
          dimension: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AppGlassIconButton(
                icon: Icons.shopping_cart_outlined,
                tooltip: hasItems ? 'Cart, $count items' : 'Cart',
                onPressed: onPressed,
              ),
              Positioned(
                top: -3,
                right: -5,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: hasItems ? 1 : 0,
                    duration: AppMotion.medium,
                    curve: Curves.easeOutBack,
                    child: Container(
                      key: const ValueKey<String>('cart-count-badge'),
                      height: 19,
                      constraints: const BoxConstraints(minWidth: 19),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: AppColors.appBar, width: 1.5),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        widthFactor: 1,
                        // A small bump each time the count changes.
                        child: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            key: ValueKey<int>(count),
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontSize: 10.5,
                              height: 1,
                              letterSpacing: 0,
                              fontFeatures: AppTextStyles.tabularFigures,
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
        ),
      ),
    );
  }
}

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

        final Widget scrollView = SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: onRefresh == null
              ? null
              : const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: child,
            ),
          ),
        );

        if (onRefresh == null) return scrollView;
        return RefreshIndicator(
          color: AppColors.primaryBright,
          backgroundColor: AppColors.surfaceRaised,
          displacement: 24,
          edgeOffset: AppSpacing.xs,
          elevation: 0,
          strokeWidth: 2.4,
          onRefresh: onRefresh!,
          child: scrollView,
        );
      },
    );
  }
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

class AppAssetImage extends StatelessWidget {
  const AppAssetImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackLabel,
  });

  final String path;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    if (path.trim().isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: _buildFallback(
          context,
          StateError('No image path was supplied.'),
          null,
        ),
      );
    }

    final bool isRemote =
        path.startsWith('http://') || path.startsWith('https://');
    final bool isDataImage =
        path.startsWith('data:image/') && path.contains(',');
    final bool isAbsoluteFile =
        path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);

    final Widget image;
    if (isDataImage) {
      try {
        image = Image.memory(
          base64Decode(path.substring(path.indexOf(',') + 1)),
          fit: fit,
          frameBuilder: _fadeInFrame,
          errorBuilder: _buildFallback,
        );
      } on FormatException catch (error, stackTrace) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: _buildFallback(context, error, stackTrace),
        );
      }
    } else if (isRemote) {
      image = Image.network(
        path,
        fit: fit,
        frameBuilder: _fadeInFrame,
        errorBuilder: _buildFallback,
      );
    } else if (isAbsoluteFile) {
      image = Image.file(
        io.File(path),
        fit: fit,
        frameBuilder: _fadeInFrame,
        errorBuilder: _buildFallback,
      );
    } else {
      image = Image.asset(
        path,
        fit: fit,
        frameBuilder: _fadeInFrame,
        errorBuilder: _buildFallback,
      );
    }

    return ClipRRect(borderRadius: borderRadius, child: image);
  }

  // Images that arrive asynchronously fade in instead of popping.
  Widget _fadeInFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: AppMotion.medium,
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _buildFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E1E22), Color(0xFF0E0E10)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(fallbackIcon, color: const Color(0x4DFFFFFF), size: 38),
            if (fallbackLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                fallbackLabel!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
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
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, ?currentChild],
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

/// Button text that shrinks to fit the button on small screens instead of
/// wrapping onto extra lines or being cut off.
class AppButtonLabel extends StatelessWidget {
  const AppButtonLabel(this.label, {super.key, this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 64,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? const SizedBox.square(
            key: ValueKey<String>('primary-loading'),
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              strokeCap: StrokeCap.round,
              color: Colors.white,
            ),
          )
        : Row(
            key: const ValueKey<String>('primary-label'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: AppButtonLabel(label, style: AppTextStyles.button),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: isLoading
            ? AppButtonStyles.primary.copyWith(
                backgroundColor: const WidgetStatePropertyAll<Color>(
                  AppColors.primary,
                ),
              )
            : AppButtonStyles.primary,
        child: AnimatedSwitcher(duration: AppMotion.fast, child: content),
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: AppButtonStyles.secondary,
        child: AppButtonLabel(label, style: AppTextStyles.button),
      ),
    );
  }
}

/// Page dots that never grow past [maxVisible]: a window follows the current
/// page, and the dots at its edges shrink and fade when more pages lie beyond
/// them. The window slides smoothly as the page changes.
class AppPageDots extends StatelessWidget {
  const AppPageDots({
    super.key,
    required this.count,
    required this.current,
    this.onSelected,
    this.activeColor = AppColors.primaryBright,
    this.inactiveColor = AppColors.textFaint,
    this.maxVisible = 5,
    this.dotSize = 7,
    this.activeWidth = 22,
    this.gap = 8,
  });

  final int count;
  final int current;
  final ValueChanged<int>? onSelected;
  final Color activeColor;
  final Color inactiveColor;
  final int maxVisible;
  final double dotSize;
  final double activeWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final int visible = count < maxVisible ? count : maxVisible;
    final int selected = current.clamp(0, count - 1);
    final int start = (selected - visible ~/ 2).clamp(0, count - visible);
    final int end = start + visible - 1;
    final double slot = dotSize + gap;
    // The active pill is always inside the window, so its width is constant.
    final double windowWidth = visible * slot + (activeWidth - dotSize);

    return SizedBox(
      width: windowWidth,
      height: dotSize + 12,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: start * slot),
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          builder: (BuildContext context, double offset, Widget? child) {
            return Transform.translate(
              offset: Offset(-offset, 0),
              child: child,
            );
          },
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(count, (int index) {
                final bool isActive = index == selected;
                final bool isOutside = index < start || index > end;
                // An edge dot with more pages beyond it.
                final bool isEdge =
                    (index == start && start > 0) ||
                    (index == end && end < count - 1);
                final Widget dot = AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  width: isActive ? activeWidth : dotSize,
                  height: dotSize,
                  margin: EdgeInsets.symmetric(
                    horizontal: gap / 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                );
                final ValueChanged<int>? select = onSelected;
                return AnimatedOpacity(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  opacity: isOutside
                      ? 0
                      : isEdge
                      ? 0.6
                      : 1,
                  child: AnimatedScale(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    scale: isEdge ? 0.7 : 1,
                    child: select == null
                        ? dot
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => select(index),
                            child: dot,
                          ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Short red rule used under section headings ("Event Overview").
class AppAccentBar extends StatelessWidget {
  const AppAccentBar({super.key, this.width = 28});

  final double width;

  @override
  Widget build(BuildContext context) {
    // Align keeps the rule short even inside stretched columns.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
            if (actionLabel != null)
              TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      actionLabel!.replaceAll('›', '').trim(),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryBright,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primaryBright,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const AppAccentBar(),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.uppercase = true,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: color,
                fontSize: uppercase ? 11 : 13,
                letterSpacing: uppercase ? 1.1 : 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Red diagonal flourish drawn in the bottom-right corner of hero cards.
class AppCornerSlashPainter extends CustomPainter {
  const AppCornerSlashPainter({this.color = AppColors.primary});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path slash = Path()
      ..moveTo(size.width, size.height * 0.42)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.70, size.height)
      ..close();
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: <Color>[
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(slash, paint);
  }

  @override
  bool shouldRepaint(covariant AppCornerSlashPainter oldDelegate) =>
      oldDelegate.color != color;
}

class MemberSummaryCard extends StatelessWidget {
  const MemberSummaryCard({
    super.key,
    required this.avatarPath,
    required this.memberName,
    required this.memberId,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    this.statusNote,
    this.showEditButton = false,
    this.onEditPressed,
  });

  final String avatarPath;
  final String memberName;
  final String memberId;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final String? statusNote;
  final bool showEditButton;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.heroPanel(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: CustomPaint(
          painter: const AppCornerSlashPainter(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.25),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: AppAssetImage(
                        path: avatarPath,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        fallbackIcon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            StatusBadge(
                              label: status,
                              color: statusColor,
                              icon: statusIcon,
                            ),
                            if (statusNote != null) ...<Widget>[
                              const SizedBox(height: AppSpacing.xs),
                              Text(statusNote!, style: AppTextStyles.caption),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (showEditButton)
                      IconButton.outlined(
                        tooltip: 'Edit profile',
                        onPressed: onEditPressed,
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _MemberValue(
                          label: 'MEMBER NAME',
                          value: memberName,
                          alignment: CrossAxisAlignment.start,
                        ),
                      ),
                      const VerticalDivider(
                        width: AppSpacing.xl,
                        color: AppColors.cardBorder,
                      ),
                      Expanded(
                        child: _MemberValue(
                          label: 'ID NUMBER',
                          value: memberId,
                          alignment: CrossAxisAlignment.start,
                          valueColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberValue extends StatelessWidget {
  const _MemberValue({
    required this.label,
    required this.value,
    required this.alignment,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
          style: AppTextStyles.overline,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment == CrossAxisAlignment.end
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              textAlign: alignment == CrossAxisAlignment.end
                  ? TextAlign.right
                  : TextAlign.left,
              style: AppTextStyles.numeric.copyWith(
                color: valueColor,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating navigation bar: a rounded glass capsule that hovers above the
/// content (from the reference), keeping the app's labelled tabs, with
/// Events as the raised red button in the middle. Slim, slightly
/// see-through, no drop shadows.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selected,
    this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection>? onSelected;

  static const Map<AppSection, IconData> _icons = <AppSection, IconData>{
    AppSection.home: Icons.home_outlined,
    AppSection.events: Icons.calendar_month_outlined,
    AppSection.shop: Icons.shopping_bag_outlined,
    AppSection.offers: Icons.card_giftcard_outlined,
    AppSection.profile: Icons.person_outline_rounded,
  };

  static const Map<AppSection, IconData> _selectedIcons =
      <AppSection, IconData>{
        AppSection.home: Icons.home_rounded,
        AppSection.events: Icons.calendar_month_rounded,
        AppSection.shop: Icons.shopping_bag_rounded,
        AppSection.offers: Icons.card_giftcard_rounded,
        AppSection.profile: Icons.person_rounded,
      };

  /// Visual order, left to right, with Events in the middle. Branch indexes
  /// (and routes) are unchanged.
  static const List<AppSection> _order = <AppSection>[
    AppSection.home,
    AppSection.shop,
    AppSection.events,
    AppSection.offers,
    AppSection.profile,
  ];

  static const double _barHeight = 58;
  static const double _overhang = 16;

  /// Slightly see-through glass (content shows faintly behind it).
  static const Color _glass = Color(0xBF141417);

  void _select(BuildContext context, AppSection section) {
    if (section == selected) return;
    HapticFeedback.selectionClick();
    final ValueChanged<AppSection>? callback = onSelected;
    if (callback != null) {
      callback(section);
    } else {
      context.goNamed(section.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          height: _barHeight + _overhang,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _glass,
                        borderRadius: BorderRadius.circular(_barHeight / 2),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: Row(
                        children: _order.map((AppSection section) {
                          return Expanded(
                            child: _NavBarItem(
                              label: section.name.toUpperCase(),
                              isSelected: section == selected,
                              icon: _icons[section]!,
                              selectedIcon: _selectedIcons[section]!,
                              // Events' icon is drawn by the raised button.
                              showIcon: section != AppSection.events,
                              onTap: () => _select(context, section),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _NavMainButton(
                    icon: selected == AppSection.events
                        ? _selectedIcons[AppSection.events]!
                        : _icons[AppSection.events]!,
                    isSelected: selected == AppSection.events,
                    onTap: () => _select(context, AppSection.events),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.showIcon = true,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.primaryBright
        : const Color(0x99FFFFFF);

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        splashColor: const Color(0x1FD5001C),
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The red selection bar from the previous navigation, now on the
            // capsule's top edge.
            if (showIcon)
              Positioned(
                top: 0,
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  width: isSelected ? 18 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBright,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(3),
                    ),
                    boxShadow: isSelected
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 22,
                  child: showIcon
                      ? AnimatedScale(
                          scale: isSelected ? 1.08 : 1,
                          duration: AppMotion.medium,
                          curve: AppMotion.curve,
                          child: AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: Icon(
                              isSelected ? selectedIcon : icon,
                              key: ValueKey<bool>(isSelected),
                              color: color,
                              size: 22,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.medium,
                    style: AppTextStyles.label.copyWith(
                      color: color,
                      fontSize: 9.5,
                      letterSpacing: 0.9,
                    ),
                    child: Text(label, maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Raised red button in the middle of the bar: the main (Events) tab.
class _NavMainButton extends StatelessWidget {
  const _NavMainButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Events',
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.06 : 1,
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primaryBright, AppColors.primary],
              ),
              // A ring in the bar's glass colour lifts it off the bar.
              border: Border.all(color: AppBottomNavigation._glass, width: 3),
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Icon(
                icon,
                key: ValueKey<IconData>(icon),
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedEvent extends StatelessWidget {
  const FeaturedEvent({super.key, required this.event, this.onPressed});

  final Event event;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      enabled: onPressed != null,
      scale: 0.985,
      child: AspectRatio(
        aspectRatio: 0.9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.large + 4),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.large + 4),
            child: Material(
              color: AppColors.panelDark,
              child: InkWell(
                onTap: onPressed,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    AppAssetImage(
                      path: event.posterUrl,
                      fallbackIcon: Icons.directions_car_outlined,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x00000000),
                            Color(0x33000000),
                            Color(0xE6050507),
                          ],
                          stops: <double>[0, 0.45, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          AppTagPill(label: event.category),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FeaturedMeta(
                            icon: Icons.calendar_today_rounded,
                            text: AppFormatters.dateAndTime(event.startsAt),
                          ),
                          const SizedBox(height: 6),
                          _FeaturedMeta(
                            icon: Icons.location_on_rounded,
                            text: event.location,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              style: AppButtonStyles.pill(),
                              onPressed: onPressed,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Flexible(
                                    child: AppButtonLabel(
                                      'View Event',
                                      style: AppTextStyles.button,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedMeta extends StatelessWidget {
  const _FeaturedMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.primaryBright),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Solid red capsule for categories and states ("UPCOMING").
class AppTagPill extends StatelessWidget {
  const AppTagPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: 10.5,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one bar button style used everywhere: the round glass button from
/// the event details page, sized for a 64px toolbar.
class AppBarButton extends StatelessWidget {
  const AppBarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.leading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: leading ? AppSpacing.md : 0,
        right: leading ? 0 : AppSpacing.xs,
      ),
      child: Center(
        child: SizedBox.square(
          dimension: 44,
          child: AppGlassIconButton(
            icon: icon,
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// Round translucent button that floats over imagery (back / share).
class AppGlassIconButton extends StatelessWidget {
  const AppGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: const Color(0x991C1C20),
          shape: const CircleBorder(side: BorderSide(color: Color(0x2EFFFFFF))),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

/// Rounded square holding a tinted icon (ticket details, stats, options).
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primaryBright,
    this.size = 44,
    this.iconSize = 22,
    this.circle = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppDecorations.iconBadge(color, circle: circle),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Horizontally scrolling pill filters (categories). Selection animates.
class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = index == selectedIndex;
          return Semantics(
            selected: isSelected,
            button: true,
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.panelDark,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBright
                        : AppColors.cardBorder,
                  ),
                  boxShadow: isSelected
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x40D5001C),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.medium,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.9,
                  ),
                  child: Text(labels[index].toUpperCase()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Segmented two-or-more option switcher with a sliding red thumb.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 48,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth / labels.length;
          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                left: width * selectedIndex,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.primaryBright,
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.medium - 4),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x40D5001C),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int index = 0; index < labels.length; index++)
                    Expanded(
                      child: Semantics(
                        selected: index == selectedIndex,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: index == selectedIndex
                              ? null
                              : () => onSelected(index),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.medium,
                              style: AppTextStyles.label.copyWith(
                                color: index == selectedIndex
                                    ? Colors.white
                                    : AppColors.textMuted,
                                letterSpacing: 1.0,
                              ),
                              child: Text(
                                labels[index].toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
