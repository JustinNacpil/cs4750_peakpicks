import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/tier_list.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'item_detail_screen.dart';

class SliderEditorScreen extends StatefulWidget {
  final TierList tierList;
  const SliderEditorScreen({super.key, required this.tierList});
  @override
  State<SliderEditorScreen> createState() => _SliderEditorScreenState();
}

class _SliderEditorScreenState extends State<SliderEditorScreen> {
  late TierList _tl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tl = widget.tierList;
  }

  Future<void> _save() async {
    _tl.updatedAt = DateTime.now();
    await StorageService.saveSingle(_tl);
  }

  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? imagePath;

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
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Add New Pick', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final source = await showDialog<ImageSource>(context: ctx,
                      builder: (c) => SimpleDialog(title: const Text('Choose Image'), children: [
                        SimpleDialogOption(onPressed: () => Navigator.pop(c, ImageSource.camera),
                          child: const Row(children: [Icon(Icons.camera_alt_rounded), SizedBox(width: 12), Text('Camera')])),
                        SimpleDialogOption(onPressed: () => Navigator.pop(c, ImageSource.gallery),
                          child: const Row(children: [Icon(Icons.photo_library_rounded), SizedBox(width: 12), Text('Gallery')])),
                      ]));
                    if (source == null) return;
                    final picked = await _picker.pickImage(source: source, maxWidth: 600);
                    if (picked != null) {
                      final dir = await getApplicationDocumentsDirectory();
                      final ext = p.extension(picked.path);
                      final dest = p.join(dir.path, 'peakpicks_${DateTime.now().millisecondsSinceEpoch}$ext');
                      await File(picked.path).copy(dest);
                      setSheetState(() => imagePath = dest);
                    }
                  },
                  child: Container(height: 100, width: double.infinity,
                    decoration: BoxDecoration(color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      image: imagePath != null ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover) : null),
                    child: imagePath == null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 32, color: AppColors.textSecondary),
                            const SizedBox(height: 4),
                            Text('Tap to add image', style: Theme.of(context).textTheme.bodySmall)])
                        : null),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Item name')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Description (optional)')),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, TierItem(name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(), imagePath: imagePath));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Add Pick', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
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

  void _moveToTier(TierItem item, String? fromTierId, String toTierId) {
    setState(() {
      if (fromTierId == null) {
        _tl.unrankedItems.removeWhere((i) => i.id == item.id);
      } else {
        _tl.tiers.where((t) => t.id == fromTierId).firstOrNull
            ?.items.removeWhere((i) => i.id == item.id);
      }
      _tl.tiers.firstWhere((t) => t.id == toTierId).items.add(item);
    });
    _save();
  }

  void _showPlacePicker(TierItem item, String? currentTierId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Place "${item.name}" on the scale',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ..._tl.tiers.map((tier) {
              final isCurrent = tier.id == currentTierId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Color(tier.colorValue),
                      borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                      tier.label == 'Amazing' ? Icons.local_fire_department :
                      tier.label == 'Good' ? Icons.thumb_up :
                      tier.label == 'Meh' ? Icons.sentiment_neutral :
                      tier.label == 'Bad' ? Icons.thumb_down :
                      Icons.block,
                      color: Colors.white, size: 18)),
                  title: Text(tier.label, style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? AppColors.textSecondary : AppColors.textPrimary)),
                  trailing: isCurrent ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isCurrent ? AppColors.surfaceLight.withValues(alpha: 0.5) : AppColors.surfaceLight,
                  onTap: isCurrent ? null : () {
                    Navigator.pop(ctx);
                    _moveToTier(item, currentTierId, tier.id);
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tl.title),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _addItem),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            if (_tl.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(_tl.description, style: Theme.of(context).textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            // Gradient slider bar
            _buildSliderBar(),
            const SizedBox(height: 20),
            // Tier zones with items
            ..._tl.tiers.asMap().entries.map((e) => _buildZone(e.key, e.value)),
            // Unranked
            _buildUnranked(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSliderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: _tl.tiers.map((t) => Color(t.colorValue)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_tl.tiers.last.label,
                  style: TextStyle(fontSize: 11, color: Color(_tl.tiers.last.colorValue),
                      fontWeight: FontWeight.w600)),
              Text(_tl.tiers.first.label,
                  style: TextStyle(fontSize: 11, color: Color(_tl.tiers.first.colorValue),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZone(int index, Tier tier) {
    final color = Color(tier.colorValue);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(tier.label, style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                const Spacer(),
                Text('${tier.items.length}', style: TextStyle(
                  fontSize: 12, color: color.withValues(alpha: 0.7))),
              ],
            ),
          ),
          // Items
          if (tier.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: tier.items.map((item) {
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<dynamic>(context,
                        MaterialPageRoute(builder: (_) => ItemDetailScreen(
                          item: item, tierList: _tl, currentTierId: tier.id)));
                      if (result == 'deleted') {
                        setState(() => tier.items.removeWhere((i) => i.id == item.id));
                        _save();
                      } else if (result is TierItem) {
                        setState(() {
                          final idx = tier.items.indexWhere((i) => i.id == result.id);
                          if (idx >= 0) tier.items[idx] = result;
                        });
                        _save();
                      }
                    },
                    onLongPress: () => _showPlacePicker(item, tier.id),
                    child: _SliderItemChip(item: item, color: color),
                  );
                }).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('No items yet',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.5))),
            ),
        ],
      ),
    );
  }

  Widget _buildUnranked() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inbox_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Text('Unplaced', style: TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text('${_tl.unrankedItems.length}', style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (_tl.unrankedItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8,
              children: _tl.unrankedItems.map((item) {
                return GestureDetector(
                  onTap: () => _showPlacePicker(item, null),
                  child: _SliderItemChip(item: item, color: AppColors.textSecondary),
                );
              }).toList()),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Tap + to add items, then place them on the scale',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _SliderItemChip extends StatelessWidget {
  final TierItem item;
  final Color color;
  const _SliderItemChip({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: Image.file(File(item.imagePath!),
                height: 60, width: 100, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 60, color: AppColors.surfaceLight,
                  child: const Icon(Icons.broken_image_rounded, size: 22))),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Text(item.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
