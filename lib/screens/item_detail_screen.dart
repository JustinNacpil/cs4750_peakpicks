import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tier_list.dart';
import '../services/cloud_storage_service.dart';
import '../theme/app_theme.dart';

class ItemDetailScreen extends StatefulWidget {
  final TierItem item;
  final TierList tierList;
  final String? currentTierId;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.tierList,
    this.currentTierId,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late String? _imageUrl;  // cloud URL
  late String? _imagePath; // local fallback
  bool _uploadingImage = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
    _imageUrl = widget.item.imageUrl;
    _imagePath = widget.item.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? get _displayImage => _imageUrl ?? _imagePath;

  String get _currentTierLabel {
    if (widget.currentTierId == null) return 'Unranked';
    return widget.tierList.tiers
        .firstWhere((t) => t.id == widget.currentTierId,
            orElse: () => widget.tierList.tiers.first)
        .label;
  }

  Color get _currentTierColor {
    if (widget.currentTierId == null) return AppColors.textSecondary;
    return Color(widget.tierList.tiers
        .firstWhere((t) => t.id == widget.currentTierId,
            orElse: () => widget.tierList.tiers.first)
        .colorValue);
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
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
    if (source == null) return;

    final picked = await _picker.pickImage(
        source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await CloudStorageService.uploadItemImage(File(picked.path));
      setState(() {
        _imageUrl = url;
        _imagePath = null; // clear local path — cloud wins
        _uploadingImage = false;
      });
    } catch (e) {
      // Upload failed — silently fall back to local image
      setState(() {
        _imagePath = picked.path;
        _uploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved locally'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _saveAndPop() {
    final updated = TierItem(
      id: widget.item.id,
      name: _nameCtrl.text.trim().isEmpty
          ? widget.item.name
          : _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imagePath: _imagePath,
      imageUrl: _imageUrl,
      createdAt: widget.item.createdAt,
    );
    Navigator.pop(context, updated);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Item'),
        content:
            Text('Remove "${widget.item.name}" from this tier list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) Navigator.pop(context, 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tier badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentTierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _currentTierColor, width: 1.5),
                ),
                child: Text(
                  _currentTierLabel,
                  style: TextStyle(
                    color: _currentTierColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Image
          GestureDetector(
            onTap: _uploadingImage ? null : _pickImage,
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _uploadingImage
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Uploading photo…',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : _displayImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            _displayImage!.startsWith('http')
                                ? Image.network(_displayImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _brokenImageWidget())
                                : Image.file(File(_displayImage!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _brokenImageWidget()),
                            Positioned(
                              bottom: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 40, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            Text('Tap to add image',
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Name', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Item name'),
          ),
          const SizedBox(height: 20),

          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'Why does this item deserve its ranking?\nAdd pros, cons, notes...',
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _uploadingImage ? null : _saveAndPop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenImageWidget() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
          child: Icon(Icons.broken_image_rounded,
              size: 40, color: AppColors.textSecondary)),
    );
  }
}
