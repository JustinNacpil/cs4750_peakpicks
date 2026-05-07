import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tier_list.dart';
import '../services/firestore_service.dart';
import '../services/cloud_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tier_row.dart';
import 'item_detail_screen.dart';

class TierListEditorScreen extends StatefulWidget {
  final TierList tierList;
  const TierListEditorScreen({super.key, required this.tierList});
  @override
  State<TierListEditorScreen> createState() => _TierListEditorScreenState();
}

class _TierListEditorScreenState extends State<TierListEditorScreen> {
  late TierList _tl;
  final _picker = ImagePicker();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tl = widget.tierList;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirestoreService.saveSingle(_tl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Pick image and upload to Firebase Storage ───
  Future<String?> _pickAndUploadImage(BuildContext ctx) async {
    final source = await _showImageSourceDialog(ctx);
    if (source == null) return null;

    final picked = await _picker.pickImage(
        source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return null;

    try {
      final url =
          await CloudStorageService.uploadItemImage(File(picked.path));
      return url;
    } catch (e) {
      // Storage not configured yet — silently return null (local path used as fallback)
      return null;
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext ctx) {
    return showDialog<ImageSource>(
      context: ctx,
      builder: (c) => SimpleDialog(
        title: const Text('Choose Image'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, ImageSource.camera),
            child: const Row(children: [
              Icon(Icons.camera_alt_rounded), SizedBox(width: 12), Text('Camera')
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, ImageSource.gallery),
            child: const Row(children: [
              Icon(Icons.photo_library_rounded), SizedBox(width: 12), Text('Gallery')
            ]),
          ),
        ],
      ),
    );
  }

  // ── Add Item bottom sheet ───────────────────────
  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? imageUrl;
    bool uploadingImage = false;

    final result = await showModalBottomSheet<TierItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add New Pick',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),

                // Image picker
                GestureDetector(
                  onTap: uploadingImage
                      ? null
                      : () async {
                          final source = await _showImageSourceDialog(ctx);
                          if (source == null) return;
                          setSheetState(() => uploadingImage = true);
                          final picked = await _picker.pickImage(
                              source: source, maxWidth: 800, imageQuality: 85);
                          if (picked != null) {
                            try {
                              final url =
                                  await CloudStorageService.uploadItemImage(
                                      File(picked.path));
                              setSheetState(() {
                                imageUrl = url;
                                uploadingImage = false;
                              });
                            } catch (_) {
                              setSheetState(() => uploadingImage = false);
                            }
                          } else {
                            setSheetState(() => uploadingImage = false);
                          }
                        },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: uploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : imageUrl != null
                            ? Image.file(File(imageUrl!), fit: BoxFit.cover,
                                width: double.infinity, height: 120)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 36, color: AppColors.textSecondary),
                              const SizedBox(height: 6),
                              Text('Tap to add image',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Item name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Why does this deserve its rank? (optional)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(
                          ctx,
                          TierItem(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            imageUrl: imageUrl,
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Pick',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );

    if (result != null) {
      setState(() => _tl.unrankedItems.add(result));
      _save();
    }
  }

  // ── Move item between tiers ─────────────────────
  void _moveItem(TierItem item, String? fromTierId, String? toTierId) {
    setState(() {
      if (fromTierId == null) {
        _tl.unrankedItems.removeWhere((i) => i.id == item.id);
      } else {
        final tier = _tl.tiers.where((t) => t.id == fromTierId).firstOrNull;
        tier?.items.removeWhere((i) => i.id == item.id);
      }
      if (toTierId == null) {
        _tl.unrankedItems.add(item);
      } else {
        final tier = _tl.tiers.where((t) => t.id == toTierId).firstOrNull;
        tier?.items.add(item);
      }
    });
    _save();
  }

  // ── Tap-to-move: show tier picker ──────────────
  void _showMovePicker(TierItem item, String? currentTierId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Move "${item.name}"',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._tl.tiers.map((tier) {
                final isCurrent = tier.id == currentTierId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(tier.colorValue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: Text(tier.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        )),
                    trailing: isCurrent
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.accent, size: 20)
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    tileColor: isCurrent
                        ? AppColors.surfaceLight.withValues(alpha: 0.5)
                        : AppColors.surfaceLight,
                    onTap: isCurrent
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _moveItem(item, currentTierId, tier.id);
                          },
                  ),
                );
              }),
              // Unranked option
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inbox_rounded,
                        size: 18, color: Colors.white),
                  ),
                  title: Text('Unranked',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: currentTierId == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      )),
                  trailing: currentTierId == null
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.accent, size: 20)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tileColor: currentTierId == null
                      ? AppColors.surfaceLight.withValues(alpha: 0.5)
                      : AppColors.surfaceLight,
                  onTap: currentTierId == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _moveItem(item, currentTierId, null);
                        },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _viewItem(TierItem item, String? tierId) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          item: item,
          tierList: _tl,
          currentTierId: tierId,
        ),
      ),
    );
    if (result == 'deleted') {
      setState(() {
        if (tierId == null) {
          _tl.unrankedItems.removeWhere((i) => i.id == item.id);
        } else {
          _tl.tiers
              .firstWhere((t) => t.id == tierId)
              .items
              .removeWhere((i) => i.id == item.id);
        }
      });
      _save();
    } else if (result is TierItem) {
      setState(() {
        if (tierId == null) {
          final idx = _tl.unrankedItems.indexWhere((i) => i.id == result.id);
          if (idx >= 0) _tl.unrankedItems[idx] = result;
        } else {
          final tier = _tl.tiers.firstWhere((t) => t.id == tierId);
          final idx = tier.items.indexWhere((i) => i.id == result.id);
          if (idx >= 0) tier.items[idx] = result;
        }
      });
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tl.title),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Item',
            onPressed: _addItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_tl.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(_tl.description,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            const SizedBox(height: 8),
            ..._tl.tiers.map((tier) => TierRow(
                  tier: tier,
                  onItemTap: (item) => _viewItem(item, tier.id),
                  onItemLongPress: (item) => _showMovePicker(item, tier.id),
                  onAcceptItem: (item, fromTierId) =>
                      _moveItem(item, fromTierId, tier.id),
                )),
            _buildUnrankedPool(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildUnrankedPool() {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final data = details.data;
        final item = data['item'] as TierItem;
        final fromId = data['fromTierId'] as String?;
        _moveItem(item, fromId, null);
      },
      builder: (ctx, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovering ? AppColors.accent : AppColors.divider,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inbox_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Unranked',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const Spacer(),
                  Text('${_tl.unrankedItems.length} items',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (_tl.unrankedItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _tl.unrankedItems.map((item) {
                    return DraggableItemChip(
                      item: item,
                      fromTierId: null,
                      onTap: () => _viewItem(item, null),
                      onLongPress: () => _showMovePicker(item, null),
                    );
                  }).toList(),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      'Long-press items to move, or drag them here',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared Draggable Item Chip ──────────────────

class DraggableItemChip extends StatelessWidget {
  final TierItem item;
  final String? fromTierId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DraggableItemChip({
    super.key,
    required this.item,
    required this.fromTierId,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final child =
        ItemChipWidget(item: item, onTap: onTap, onLongPress: onLongPress);
    return LongPressDraggable<Map<String, dynamic>>(
      data: {'item': item, 'fromTierId': fromTierId},
      delay: const Duration(milliseconds: 300),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: ItemChipWidget(item: item, onTap: () {}, onLongPress: () {}),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

class ItemChipWidget extends StatelessWidget {
  final TierItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const ItemChipWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final displayImg = item.displayImage;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 110),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayImg != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(9)),
                child: displayImg.startsWith('http')
                    ? Image.network(
                        displayImg,
                        height: 65, width: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 65, color: AppColors.surfaceLight,
                          child: const Icon(Icons.broken_image_rounded,
                              size: 24),
                        ),
                      )
                    : Image.file(
                        File(displayImg),
                        height: 65, width: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 65, color: AppColors.surfaceLight,
                          child: const Icon(Icons.broken_image_rounded,
                              size: 24),
                        ),
                      ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Text(
                item.name,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
