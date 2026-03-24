import 'package:flutter/material.dart';
import '../models/tier_list.dart';
import '../theme/app_theme.dart';

class CreateTierListScreen extends StatefulWidget {
  const CreateTierListScreen({super.key});
  @override
  State<CreateTierListScreen> createState() => _CreateTierListScreenState();
}

class _CreateTierListScreenState extends State<CreateTierListScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TierStyleType _style = TierStyleType.worthIt;

  void _create() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your tier list a title')));
      return;
    }

    List<TierPreset> presets;
    switch (_style) {
      case TierStyleType.worthIt:
        presets = worthItPresets;
      case TierStyleType.classic:
        presets = classicPresets;
      case TierStyleType.slider:
        presets = sliderPresets;
      case TierStyleType.bracket:
        presets = bracketPresets;
    }

    final tiers =
        presets.map((p) => Tier(label: p.label, colorValue: p.colorValue)).toList();

    final tl = TierList(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      styleType: _style,
      tiers: tiers,
    );
    Navigator.pop(context, tl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Tier List')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Title', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. Best Headphones 2026'),
          ),
          const SizedBox(height: 20),
          Text('Description (optional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'What is this tier list about?'),
          ),
          const SizedBox(height: 28),
          Text('Choose a Style', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildStyleCard(
            type: TierStyleType.worthIt,
            title: 'Worth It Scale',
            subtitle: 'MUST BUY → SCAM',
            icon: Icons.star_rounded,
            presets: worthItPresets,
          ),
          const SizedBox(height: 10),
          _buildStyleCard(
            type: TierStyleType.classic,
            title: 'Classic S-Tier',
            subtitle: 'S → A → B → C → D → F',
            icon: Icons.format_list_numbered_rounded,
            presets: classicPresets,
          ),
          const SizedBox(height: 10),
          _buildStyleCard(
            type: TierStyleType.slider,
            title: 'Slider Scale',
            subtitle: 'Never ← → Amazing',
            icon: Icons.tune_rounded,
            presets: sliderPresets,
          ),
          const SizedBox(height: 10),
          _buildStyleCard(
            type: TierStyleType.bracket,
            title: 'Bracket Battle',
            subtitle: 'Tournament style',
            icon: Icons.emoji_events_rounded,
            presets: bracketPresets,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: const Text('Create Tier List'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStyleCard({
    required TierStyleType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<TierPreset> presets,
  }) {
    final selected = _style == type;
    return GestureDetector(
      onTap: () => setState(() => _style = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 20,
                    color: selected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: presets.map((p) {
                return Expanded(
                  child: Container(
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Color(p.colorValue),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.label,
                      style: const TextStyle(
                          fontSize: 7, fontWeight: FontWeight.w700,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
