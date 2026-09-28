import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';

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
