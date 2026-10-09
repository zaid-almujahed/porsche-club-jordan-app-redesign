import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';

const Color _glass = Color(0x991C1C20);
const Color _glassEdge = Color(0x2EFFFFFF);

/// Rings the badges, so they stand apart from their icon.
const BorderSide _badgeRing = BorderSide(color: Color(0xFF1C1C20), width: 1.5);

/// The page's controls in glass pills, floating over its content: on the
/// left a pill naming the page, which also goes back; on the right one pill
/// grouping the actions. The main tabs, named by the bottom bar, only show
/// their actions: the cart on the left, the bell on the right.
///
/// Pages extend their body behind it (`extendBodyBehindAppBar`), so their
/// content scrolls under the pills and fades out beneath them.
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
  Size get preferredSize => const Size.fromHeight(60);

  /// The main tabs carry the bell and are named by the bottom bar.
  bool get _showsTitle => showBack || !showNotifications;

  @override
  Widget build(BuildContext context) {
    // System back follows the same rule as the on-screen back button.
    return AppBackScope(
      enabled: showBack,
      onBack: onBack,
      child: _buildBar(context),
    );
  }

  Widget _buildBar(BuildContext context) {
    final Color background =
        Scaffold.maybeOf(context)?.widget.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final Widget? cart = showCart
        ? _CartButton(
            onPressed: onCartPressed ?? () {},
            itemCount: cartItemCount,
          )
        : null;
    // On a main tab the cart leads, across from the bell.
    final bool cartLeads = cart != null && !_showsTitle;
    final List<Widget> actions = <Widget>[
      if (cart != null && !cartLeads) cart,
      if (showNotifications)
        _NotificationButton(
          onPressed: onNotificationsPressed ?? () {},
          unreadCount: unreadNotificationCount,
        ),
      if (showClose)
        _PillIconButton(
          icon: Icons.close_rounded,
          tooltip: closeTooltip,
          onPressed: onClose,
        ),
      if (showEdit)
        _PillIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit application',
          onPressed: onEdit,
        ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons over the dark page, as the app bar had.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: DecoratedBox(
        // Content scrolling under the status bar and the pills fades out.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              background,
              background.withValues(alpha: 0.85),
              background.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.6, 1],
          ),
        ),
        // A faint red glow at the top of every page, behind the pills.
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1,
              colors: <Color>[
                Color(0x1AD5001C),
                Color(0x0AD5001C),
                Color(0x00D5001C),
              ],
              stops: <double>[0, 0.5, 1],
              transform: _WidenedGlow(),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    if (_showsTitle)
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _TitlePill(
                            title: title,
                            // Pops when there is history; otherwise (redirected
                            // or `go` routes) goes to the page's parent instead
                            // of doing nothing.
                            onBack: showBack
                                ? (onBack ?? () => context.goBack())
                                : null,
                          ),
                        ),
                      )
                    else ...<Widget>[
                      if (cartLeads) _actionsPill(<Widget>[cart]),
                      const Spacer(),
                    ],
                    if (actions.isNotEmpty) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      _actionsPill(actions),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Glass pill grouping [buttons], a hairline between each.
  Widget _actionsPill(List<Widget> buttons) {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < buttons.length; i++) ...<Widget>[
            if (i > 0) Container(width: 1, height: 20, color: _glassEdge),
            buttons[i],
          ],
        ],
      ),
    );
  }
}

/// Widens the top glow across the page: a circle stretched sideways.
class _WidenedGlow extends GradientTransform {
  const _WidenedGlow();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double centre = bounds.center.dx;
    return Matrix4.translationValues(centre, 0, 0)
      ..multiply(Matrix4.diagonal3Values(2.2, 1, 1))
      ..multiply(Matrix4.translationValues(-centre, 0, 0));
  }
}

/// A glass capsule: the shared look of the floating controls.
class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    required this.padding,
    this.onPressed,
    this.tooltip,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget pill = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: _glass,
          shape: const StadiumBorder(side: BorderSide(color: _glassEdge)),
          child: InkWell(
            onTap: onPressed,
            child: Container(height: 44, padding: padding, child: child),
          ),
        ),
      ),
    );
    final String? message = tooltip;
    if (message == null) return pill;
    return Tooltip(message: message, child: pill);
  }
}

/// The page's name; with [onBack], it is also the way back.
class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.title, required this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = onBack != null;
    return _GlassPill(
      padding: EdgeInsets.fromLTRB(canGoBack ? 12 : 18, 0, 18, 0),
      onPressed: onBack,
      tooltip: canGoBack ? 'Back' : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (canGoBack) ...<Widget>[
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(
                fontSize: 15,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon in the actions pill, with an optional badge in its corner.
class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badge,
    this.badgeOffset = Offset.zero,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Widget? badge;

  /// The badge's top and right inset.
  final Offset badgeOffset;

  @override
  Widget build(BuildContext context) {
    final Widget? corner = badge;
    return SizedBox.square(
      dimension: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            icon: Icon(icon, color: Colors.white, size: 21),
          ),
          if (corner != null)
            Positioned(
              top: badgeOffset.dy,
              right: badgeOffset.dx,
              child: IgnorePointer(child: corner),
            ),
        ],
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
    return _PillIconButton(
      icon: Icons.notifications_none_rounded,
      tooltip: hasUnread
          ? 'Notifications, $unreadCount unread'
          : 'Notifications',
      onPressed: onPressed,
      badgeOffset: const Offset(9, 8),
      badge: AnimatedScale(
        scale: hasUnread ? 1 : 0,
        duration: AppMotion.medium,
        curve: Curves.easeOutBack,
        child: Container(
          key: const ValueKey<String>('unread-notifications-dot'),
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.primaryBright,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(_badgeRing),
            boxShadow: <BoxShadow>[
              BoxShadow(color: AppColors.primaryGlow, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart button with a live item-count badge.
class _CartButton extends StatelessWidget {
  const _CartButton({required this.onPressed, required this.itemCount});

  final VoidCallback onPressed;
  final ValueListenable<int>? itemCount;

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
    return _PillIconButton(
      icon: Icons.shopping_cart_outlined,
      tooltip: hasItems ? 'Cart, $count items' : 'Cart',
      onPressed: onPressed,
      badgeOffset: const Offset(1, 3),
      badge: AnimatedScale(
        scale: hasItems ? 1 : 0,
        duration: AppMotion.medium,
        curve: Curves.easeOutBack,
        child: Container(
          key: const ValueKey<String>('cart-count-badge'),
          height: 18,
          constraints: const BoxConstraints(minWidth: 18),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: const Border.fromBorderSide(_badgeRing),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: AppColors.primaryGlow, blurRadius: 6),
            ],
          ),
          child: Center(
            widthFactor: 1,
            // A small bump each time the count changes.
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                count > 99 ? '99+' : '$count',
                key: ValueKey<int>(count),
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1,
                  letterSpacing: 0,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round glass button sized for a 64px toolbar (event details, sign-in).
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
          color: _glass,
          shape: const CircleBorder(side: BorderSide(color: _glassEdge)),
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
