import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tier_list.dart';
import '../theme/app_theme.dart';

class TierRow extends StatelessWidget {
  final Tier tier;
  final void Function(TierItem item) onItemTap;
  final void Function(TierItem item) onItemLongPress;
  final void Function(TierItem item, String? fromTierId) onAcceptItem;

  const TierRow({
    super.key,
    required this.tier,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onAcceptItem,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = Color(tier.colorValue);
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final data = details.data;
        final item = data['item'] as TierItem;
        final fromId = data['fromTierId'] as String?;
        if (fromId != tier.id) {
          onAcceptItem(item, fromId);
        }
      },
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: isHovering
                ? tierColor.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovering ? tierColor : AppColors.divider,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tier label
                Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Text(
                    tier.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                // Items area
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80),
                    child: tier.items.isEmpty
                        ? Center(
                            child: Text(
                              isHovering ? 'Drop here!' : 'Long-press items to move here',
                              style: TextStyle(
                                color: isHovering
                                    ? tierColor
                                    : AppColors.textSecondary.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight:
                                    isHovering ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Row(
                              children: tier.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _DraggableChip(
                                    item: item,
                                    tierId: tier.id,
                                    onTap: () => onItemTap(item),
                                    onLongPress: () => onItemLongPress(item),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DraggableChip extends StatelessWidget {
  final TierItem item;
  final String tierId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DraggableChip({
    required this.item,
    required this.tierId,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final chip = _Chip(item: item, onTap: onTap, onLongPress: onLongPress);
    return LongPressDraggable<Map<String, dynamic>>(
      data: {'item': item, 'fromTierId': tierId},
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: _Chip(item: item, onTap: () {}, onLongPress: () {}),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      child: chip,
    );
  }
}

class _Chip extends StatelessWidget {
  final TierItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Chip({required this.item, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.imagePath != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.file(
                  File(item.imagePath!),
                  height: 56, width: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 56, width: 90,
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image_rounded,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
