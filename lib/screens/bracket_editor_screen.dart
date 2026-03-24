import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pp;
import '../models/tier_list.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BracketEditorScreen extends StatefulWidget {
  final TierList tierList;
  const BracketEditorScreen({super.key, required this.tierList});
  @override
  State<BracketEditorScreen> createState() => _BracketEditorScreenState();
}

class _BracketEditorScreenState extends State<BracketEditorScreen> {
  late TierList _tl;
  final _picker = ImagePicker();
  bool _bracketStarted = false;
  int _currentRound = 0;
  String? _championId;

  @override
  void initState() {
    super.initState();
    _tl = widget.tierList;
    if (_tl.bracketMatchups.isNotEmpty) {
      _bracketStarted = true;
      _currentRound = _tl.bracketMatchups.map((m) => m.round).reduce(max);
      _checkChampion();
    }
  }

  Future<void> _save() async {
    _tl.updatedAt = DateTime.now();
    await StorageService.saveSingle(_tl);
  }

  List<TierItem> get _allContestants => _tl.unrankedItems;

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
            padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Add Contestant', style: Theme.of(context).textTheme.headlineMedium),
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
                      final ext = pp.extension(picked.path);
                      final dest = pp.join(dir.path, 'peakpicks_${DateTime.now().millisecondsSinceEpoch}$ext');
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
                  decoration: const InputDecoration(hintText: 'Contestant name')),
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
                    child: const Text('Add Contestant', style: TextStyle(fontWeight: FontWeight.w700)),
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

  void _startBracket() {
    if (_allContestants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 contestants to start')));
      return;
    }

    final items = List<TierItem>.from(_allContestants);
    items.shuffle(Random());

    final matchups = <BracketMatchup>[];
    for (int i = 0; i < items.length - 1; i += 2) {
      matchups.add(BracketMatchup(
        item1Id: items[i].id,
        item2Id: items[i + 1].id,
        round: 1,
      ));
    }
    // If odd number, last item gets a bye (auto-advance)
    if (items.length.isOdd) {
      matchups.add(BracketMatchup(
        item1Id: items.last.id,
        item2Id: items.last.id, // bye
        winnerId: items.last.id,
        round: 1,
      ));
    }

    setState(() {
      _tl.bracketMatchups = matchups;
      _bracketStarted = true;
      _currentRound = 1;
      _championId = null;
    });
    _save();
  }

  void _pickWinner(BracketMatchup matchup, String winnerId) {
    HapticFeedback.mediumImpact();
    setState(() {
      matchup.winnerId = winnerId;
    });

    // Check if all matchups in current round are decided
    final currentMatchups = _tl.bracketMatchups.where((m) => m.round == _currentRound).toList();
    final allDecided = currentMatchups.every((m) => m.winnerId != null);

    if (allDecided) {
      final winners = currentMatchups.map((m) => m.winnerId!).toList();
      if (winners.length == 1) {
        // Champion!
        setState(() => _championId = winners.first);
      } else {
        // Create next round
        final nextRound = _currentRound + 1;
        final nextMatchups = <BracketMatchup>[];
        for (int i = 0; i < winners.length - 1; i += 2) {
          nextMatchups.add(BracketMatchup(
            item1Id: winners[i],
            item2Id: winners[i + 1],
            round: nextRound,
          ));
        }
        if (winners.length.isOdd) {
          nextMatchups.add(BracketMatchup(
            item1Id: winners.last,
            item2Id: winners.last,
            winnerId: winners.last,
            round: nextRound,
          ));
        }
        setState(() {
          _tl.bracketMatchups.addAll(nextMatchups);
          _currentRound = nextRound;
        });

        // Check again (byes can auto-complete a round)
        _checkAutoAdvance();
      }
    }
    _save();
  }

  void _checkAutoAdvance() {
    final currentMatchups = _tl.bracketMatchups.where((m) => m.round == _currentRound).toList();
    final allDecided = currentMatchups.every((m) => m.winnerId != null);
    if (allDecided) {
      final winners = currentMatchups.map((m) => m.winnerId!).toList();
      if (winners.length == 1) {
        setState(() => _championId = winners.first);
      }
    }
  }

  void _checkChampion() {
    final maxRound = _tl.bracketMatchups.map((m) => m.round).reduce(max);
    final lastRoundMatchups = _tl.bracketMatchups.where((m) => m.round == maxRound).toList();
    if (lastRoundMatchups.length == 1 && lastRoundMatchups.first.winnerId != null) {
      _championId = lastRoundMatchups.first.winnerId;
    }
  }

  void _resetBracket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset Bracket'),
        content: const Text('Start over with a new bracket? All matchup results will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _tl.bracketMatchups.clear();
        _bracketStarted = false;
        _currentRound = 0;
        _championId = null;
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
          if (!_bracketStarted)
            IconButton(icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: _addItem),
          if (_bracketStarted)
            IconButton(icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Bracket',
              onPressed: _resetBracket),
        ],
      ),
      body: _bracketStarted ? _buildBracketView() : _buildSetupView(),
      floatingActionButton: _bracketStarted
          ? null
          : FloatingActionButton(onPressed: _addItem,
              child: const Icon(Icons.add_rounded)),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tl.description.isNotEmpty) ...[
            Text(_tl.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.surface],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.accent),
                const SizedBox(height: 12),
                Text('Bracket Battle', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Add contestants, then start the bracket to pick your champion!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Contestants (${_allContestants.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_allContestants.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(child: Text('Tap + to add contestants',
                  style: Theme.of(context).textTheme.bodyMedium)),
            )
          else
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _allContestants.map((item) => _ContestantChip(item: item)).toList(),
            ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _allContestants.length >= 2 ? _startBracket : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Bracket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_allContestants.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(child: Text('Need at least 2 contestants',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ),
        ],
      ),
    );
  }

  Widget _buildBracketView() {
    final roundMatchups = _tl.bracketMatchups.where((m) => m.round == _currentRound).toList();
    final undecided = roundMatchups.where((m) => m.winnerId == null).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Champion banner
          if (_championId != null) ...[
            _buildChampionBanner(),
            const SizedBox(height: 20),
          ],
          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _championId != null ? 'Final Results' : 'Round $_currentRound',
              style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          // Current matchups
          if (_championId == null && undecided.isNotEmpty)
            ...undecided.map((m) => _buildMatchupCard(m))
          else if (_championId == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Advancing to next round...',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          // Completed matchups in this round
          if (roundMatchups.where((m) => m.winnerId != null).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Completed', style: TextStyle(fontSize: 12,
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...roundMatchups.where((m) => m.winnerId != null && m.item1Id != m.item2Id)
                .map((m) => _buildCompletedMatchup(m)),
          ],
        ],
      ),
    );
  }

  Widget _buildChampionBanner() {
    final champ = _tl.findItem(_championId!);
    if (champ == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFD700).withValues(alpha: 0.2), AppColors.surface],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Column(
        children: [
          const Text('CHAMPION', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800,
            color: Color(0xFFFFD700), letterSpacing: 2)),
          const SizedBox(height: 10),
          if (champ.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(champ.imagePath!),
                height: 80, width: 80, fit: BoxFit.cover),
            ),
          const SizedBox(height: 10),
          Text(champ.name, style: Theme.of(context).textTheme.headlineMedium),
          if (champ.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(champ.description, style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchupCard(BracketMatchup matchup) {
    final item1 = _tl.findItem(matchup.item1Id);
    final item2 = _tl.findItem(matchup.item2Id);
    if (item1 == null || item2 == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('VS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildContestantButton(item1, matchup)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 28),
              ),
              Expanded(child: _buildContestantButton(item2, matchup)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tap to pick the winner', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildContestantButton(TierItem item, BracketMatchup matchup) {
    return GestureDetector(
      onTap: () => _pickWinner(matchup, item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            if (item.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(item.imagePath!),
                  height: 60, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 60,
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image_rounded, size: 24))),
              )
            else
              Container(
                height: 60, width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_rounded, size: 30, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 8),
            Text(item.name, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedMatchup(BracketMatchup matchup) {
    final item1 = _tl.findItem(matchup.item1Id);
    final item2 = _tl.findItem(matchup.item2Id);
    final winner = _tl.findItem(matchup.winnerId!);
    if (item1 == null || item2 == null || winner == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(item1.name, style: TextStyle(fontSize: 13,
            fontWeight: item1.id == winner.id ? FontWeight.w700 : FontWeight.normal,
            color: item1.id == winner.id ? AppColors.accent : AppColors.textSecondary)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('vs', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          Text(item2.name, style: TextStyle(fontSize: 13,
            fontWeight: item2.id == winner.id ? FontWeight.w700 : FontWeight.normal,
            color: item2.id == winner.id ? AppColors.accent : AppColors.textSecondary)),
          const Spacer(),
          const Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _ContestantChip extends StatelessWidget {
  final TierItem item;
  const _ContestantChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: Image.file(File(item.imagePath!),
                height: 60, width: 100, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 60, color: AppColors.surfaceLight)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Text(item.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
