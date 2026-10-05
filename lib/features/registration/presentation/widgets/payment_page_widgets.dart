import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class PaymentMethodTile extends StatefulWidget {
  const PaymentMethodTile({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
    this.subtitle,
    this.icon = Icons.credit_card_rounded,
    this.comingSoon = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  /// Second line, e.g. accepted cards and the processor.
  final String? subtitle;
  final IconData icon;

  /// Not offered yet: greyed out, and a tap shakes it and says "Coming Soon".
  final bool comingSoon;

  @override
  State<PaymentMethodTile> createState() => _PaymentMethodTileState();
}

class _PaymentMethodTileState extends State<PaymentMethodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Timer? _hideSoon;
  bool _showSoon = false;

  void _tapComingSoon() {
    HapticFeedback.selectionClick();
    _shake.forward(from: 0);
    _hideSoon?.cancel();
    setState(() => _showSoon = true);
    _hideSoon = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSoon = false);
    });
  }

  @override
  void dispose() {
    _hideSoon?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final double fade = widget.comingSoon ? 0.4 : 1;
    final Widget tile = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.07),
                AppColors.panelDark,
              )
            : AppColors.panelDark,
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadii.medium + 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.comingSoon ? _tapComingSoon : widget.onPressed,
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Opacity(
                    opacity: fade,
                    child: AppIconBadge(
                      icon: widget.icon,
                      color: selected
                          ? AppColors.primaryBright
                          : AppColors.textMuted,
                      size: 42,
                      iconSize: 21,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Opacity(
                      opacity: fade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.label,
                            style: AppTextStyles.title.copyWith(fontSize: 16),
                          ),
                          if (widget.subtitle != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    layoutBuilder: (Widget? current, List<Widget> previous) =>
                        AppMotion.switcherLayout(
                          current,
                          previous,
                          alignment: Alignment.centerRight,
                        ),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            ),
                    child: _showSoon
                        ? const AppTagPill(
                            key: ValueKey<String>('soon'),
                            label: 'Coming Soon',
                            color: AppColors.accentSteel,
                          )
                        : Opacity(
                            key: const ValueKey<String>('radio'),
                            opacity: fade,
                            child: AnimatedContainer(
                              duration: AppMotion.medium,
                              curve: AppMotion.curve,
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primaryBright
                                      : AppColors.textFaint,
                                  width: selected ? 6.5 : 1.5,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      hint: widget.comingSoon ? 'Coming soon' : null,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (BuildContext context, Widget? child) {
          final double t = _shake.value;
          return Transform.translate(
            offset: Offset(math.sin(t * math.pi * 6) * 6 * (1 - t), 0),
            child: child,
          );
        },
        child: tile,
      ),
    );
  }
}

/// Plan card at the top of checkout: what is being bought, the price per
/// year, the period it covers and what membership includes.
class MembershipPlanCard extends StatelessWidget {
  const MembershipPlanCard({super.key, required this.membership});

  final Membership membership;

  static const List<String> _benefits = <String>[
    'Club drives, meets and events',
    'Exclusive partner offers',
    'Member shop access',
  ];

  @override
  Widget build(BuildContext context) {
    final double? amount = membership.annualFee;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E1E22), Color(0xFF0C0C0E)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const AppIconBadge(
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.accentGold,
                      size: 40,
                      iconSize: 21,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ANNUAL MEMBERSHIP',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.accentGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Porsche Club Jordan',
                            style: AppTextStyles.title.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (amount != null)
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: AppFormatters.money(
                            amount,
                            membership.currency,
                          ),
                          style: AppTextStyles.numeric.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: '  / year',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Annual fee shown at payment',
                    style: AppTextStyles.title.copyWith(fontSize: 20),
                  ),
                const SizedBox(height: 6),
                const Text(
                  '12 months of membership, starting when payment is '
                  'confirmed',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0x0DFFFFFF),
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              children: <Widget>[
                for (final String benefit in _benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            benefit,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gift / referral code: one quiet row that expands into the code field.
class PromoCodeSection extends StatefulWidget {
  const PromoCodeSection({
    super.key,
    required this.controller,
    required this.isApplying,
    required this.onApply,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool isApplying;
  final VoidCallback onApply;
  final bool enabled;

  @override
  State<PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<PromoCodeSection> {
  late bool _expanded = widget.controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    // Codes are single use: one typed here is not kept for the next visit.
    widget.controller.clear();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (!_expanded) return;
    // Once open, bring the field and Apply above the fixed pay bar.
    Future<void>.delayed(AppMotion.medium, () {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(AppRadii.medium + 2),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.redeem_outlined,
                      size: 20,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Have a gift or referral code?',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppMotion.medium,
                      curve: AppMotion.curve,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            enabled: widget.enabled,
                            style: AppTextStyles.input,
                            textInputAction: TextInputAction.done,
                            // The keyboard must not learn or suggest codes.
                            autocorrect: false,
                            enableSuggestions: false,
                            enableIMEPersonalizedLearning: false,
                            decoration: const InputDecoration(
                              hintText: '12-digit code',
                            ),
                            onSubmitted: (_) => widget.onApply(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 92,
                            maxWidth: 124,
                          ),
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: widget.enabled && !widget.isApplying
                                  ? widget.onApply
                                  : null,
                              style: AppButtonStyles.inline(),
                              child: AnimatedSwitcher(
                                duration: AppMotion.fast,
                                layoutBuilder: AppMotion.switcherLayout,
                                child: widget.isApplying
                                    ? const SizedBox.square(
                                        key: ValueKey<String>('applying'),
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const AppButtonLabel(
                                        'Apply',
                                        key: ValueKey<String>('apply'),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fixed bottom bar: the pay button and a secure-payment note.
class PaymentCheckoutBar extends StatelessWidget {
  const PaymentCheckoutBar({
    super.key,
    required this.buttonLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String buttonLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.appBar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PrimaryActionButton(
                label: buttonLabel,
                height: 54,
                isLoading: isLoading,
                onPressed: onPressed,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.textFaint,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'An admin confirms CliQ payments, usually within a day. '
                      'Access starts once yours is confirmed.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
