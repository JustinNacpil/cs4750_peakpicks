import 'package:flutter/material.dart';
import '../models/tier_list.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/peak_picks_logo.dart';
import 'create_tier_list_screen.dart';
import 'tier_list_editor_screen.dart';
import 'slider_editor_screen.dart';
import 'bracket_editor_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  List<TierList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final lists = await FirestoreService.loadAll();
      if (mounted) setState(() { _lists = lists; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load lists: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openEditor(TierList tl) async {
    Widget screen;
    switch (tl.styleType) {
      case TierStyleType.slider:
        screen = SliderEditorScreen(tierList: tl);
      case TierStyleType.bracket:
        screen = BracketEditorScreen(tierList: tl);
      default:
        screen = TierListEditorScreen(tierList: tl);
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load(); // Refresh after returning from editor
  }

  Future<void> _createNew() async {
    final result = await Navigator.push<TierList>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTierListScreen()),
    );
    if (result != null) {
      await FirestoreService.saveSingle(result);
      if (mounted) _openEditor(result);
    }
  }

  Future<void> _delete(TierList tl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tier List'),
        content: Text('Delete "${tl.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreService.delete(tl.id);
      _load();
    }
  }

  String _styleLabel(TierStyleType t) {
    switch (t) {
      case TierStyleType.worthIt: return 'Worth It Scale';
      case TierStyleType.classic: return 'Classic S-Tier';
      case TierStyleType.slider: return 'Slider Scale';
      case TierStyleType.bracket: return 'Bracket Battle';
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

  int _totalItems(TierList tl) {
    int count = tl.unrankedItems.length;
    for (final tier in tl.tiers) count += tier.items.length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabIndex == 0 ? _buildHomeBody() : const ProfileScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 0) _load(); // Refresh when coming back to home
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.accent),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _createNew,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New List'),
            )
          : null,
    );
  }

  Widget _buildHomeBody() {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: PeakPicksLogo(height: 38),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _lists.isEmpty ? _buildEmpty() : _buildList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_list_bulleted_rounded,
                  size: 72,
                  color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('No tier lists yet',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Tap "New List" to create your first one',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _lists.length,
      itemBuilder: (_, i) {
        final tl = _lists[i];
        return Dismissible(
          key: Key(tl.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
          confirmDismiss: (_) async {
            _delete(tl);
            return false;
          },
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEditor(tl),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: tl.tiers.isNotEmpty
                            ? Color(tl.tiers.first.colorValue)
                                .withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _styleIcon(tl.styleType),
                        color: tl.tiers.isNotEmpty
                            ? Color(tl.tiers.first.colorValue)
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tl.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${_styleLabel(tl.styleType)}  •  ${_totalItems(tl)} items',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
