import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class ColorSelector extends StatelessWidget {
  const ColorSelector({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
  });

  final List<ProductColorOption> colors;
  final ProductColorOption? selectedColor;
  final ValueChanged<ProductColorOption> onSelected;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();
    final String selectedColorName = AppFormatters.initCap(
      selectedColor?.name ?? '',
    );
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('COLOR', style: AppTextStyles.overline),
            const Spacer(),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                selectedColorName,
                key: ValueKey<String>(selectedColorName),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: colors.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final ProductColorOption option = colors[index];
              final bool selected = option == selectedColor;
              final String colorName = AppFormatters.initCap(option.name);
              return Semantics(
                button: true,
                selected: selected,
                label: colorName,
                child: GestureDetector(
                  onTap: () => onSelected(option),
                  child: AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    width: 52,
                    padding: EdgeInsets.all(selected ? 4 : 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBright
                            : AppColors.cardBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(option.argbValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SizeSelector extends StatelessWidget {
  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selectedSize,
    required this.onSelected,
  });

  final List<String> sizes;
  final String? selectedSize;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (sizes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('SIZE', style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: sizes.map((String size) {
            final bool selected = size == selectedSize;
            return Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                onTap: () => onSelected(size),
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  // No 'alignment' here: inside a Wrap it made every chip
                  // stretch to the full row width.
                  constraints: const BoxConstraints(minWidth: 52),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.panelDark,
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryBright
                          : AppColors.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.small + 2),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      size,
                      style: AppTextStyles.label.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
  });

  final int quantity;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Text('QUANTITY', style: AppTextStyles.overline)),
        AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.panelDark,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: 'Decrease quantity',
                  visualDensity: VisualDensity.compact,
                  onPressed: enabled && quantity > 1 ? onDecrement : null,
                  icon: const Icon(Icons.remove_rounded, size: 20),
                ),
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$quantity',
                      key: ValueKey<int>(quantity),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.numeric,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Increase quantity',
                  visualDensity: VisualDensity.compact,
                  onPressed: enabled && canIncrement ? onIncrement : null,
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProductThumbnails extends StatelessWidget {
  const ProductThumbnails({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> images;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.curve,
              width: 72,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? AppColors.primaryBright
                      : AppColors.cardBorder,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadii.medium + 2),
              ),
              child: AnimatedOpacity(
                duration: AppMotion.medium,
                opacity: selected ? 1 : 0.6,
                child: AppAssetImage(
                  path: images[index],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.medium - 1),
                  ),
                  fallbackIcon: Icons.checkroom_rounded,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
