import 'package:flutter/material.dart';
import '../models/tier_list.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<TierList> _lists = [];
  bool _loading = true;
  String _displayName = 'My Profile';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lists = await StorageService.loadAll();
    setState(() {
      _lists = lists;
      _loading = false;
    });
  }

  int get _totalItems {
    int count = 0;
    for (final tl in _lists) {
      count += tl.unrankedItems.length;
      for (final t in tl.tiers) {
        count += t.items.length;
      }
    }
    return count;
  }

  Map<TierStyleType, int> get _styleCounts {
    final map = <TierStyleType, int>{};
    for (final tl in _lists) {
      map[tl.styleType] = (map[tl.styleType] ?? 0) + 1;
    }
    return map;
  }

  void _editName() async {
    final ctrl = TextEditingController(text: _displayName == 'My Profile' ? '' : _displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _displayName = result);
    }
  }

  String _styleLabel(TierStyleType t) {
    switch (t) {
      case TierStyleType.worthIt: return 'Worth It';
      case TierStyleType.classic: return 'Classic';
      case TierStyleType.slider: return 'Slider';
      case TierStyleType.bracket: return 'Bracket';
    }
  }

  IconData _styleIcon(TierStyleType t) {
    switch (t) {
      case TierStyleType.worthIt: return Icons.star_rounded;
      case TierStyleType.classic: return Icons.format_list_numbered_rounded;
      case TierStyleType.slider: return Icons.tune_rounded;
      case TierStyleType.bracket: return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar + Name
                  GestureDetector(
                    onTap: _editName,
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _displayName.isNotEmpty
                                  ? _displayName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800,
                                color: AppColors.accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_displayName,
                                style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(width: 6),
                            Icon(Icons.edit_rounded, size: 16,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Stats row
                  Row(
                    children: [
                      _StatCard(label: 'Tier Lists', value: '${_lists.length}',
                          icon: Icons.list_alt_rounded),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Total Picks', value: '$_totalItems',
                          icon: Icons.inventory_2_rounded),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Styles Used',
                          value: '${_styleCounts.length}',
                          icon: Icons.palette_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Style breakdown
                  if (_styleCounts.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Your Styles',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 12),
                    ..._styleCounts.entries.map((e) => _buildStyleRow(e.key, e.value)),
                  ],
                  const SizedBox(height: 24),
                  // Recent activity
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent Lists',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  if (_lists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text('No tier lists yet. Create one to get started!',
                          style: Theme.of(context).textTheme.bodyMedium),
                    )
                  else
                    ..._lists.take(5).map((tl) => _buildRecentListTile(tl)),
                ],
              ),
            ),
    );
  }

  Widget _buildStyleRow(TierStyleType style, int count) {
    final total = _lists.length;
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(_styleIcon(style), size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Text(_styleLabel(style),
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14, color: AppColors.textPrimary)),
          const Spacer(),
          Text('$count', style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.accent)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentListTile(TierList tl) {
    int itemCount = tl.unrankedItems.length;
    for (final t in tl.tiers) itemCount += t.items.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: tl.tiers.isNotEmpty
                  ? Color(tl.tiers.first.colorValue).withValues(alpha: 0.2)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_styleIcon(tl.styleType), size: 18,
              color: tl.tiers.isNotEmpty
                  ? Color(tl.tiers.first.colorValue)
                  : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tl.title, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                Text('${_styleLabel(tl.styleType)} • $itemCount items',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
