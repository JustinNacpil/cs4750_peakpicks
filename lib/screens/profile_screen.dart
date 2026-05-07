import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/tier_list.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<TierList> _lists = [];
  bool _loading = true;

  User? get _user => FirebaseAuth.instance.currentUser;
  bool get _isGuest => _user?.isAnonymous ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lists = await FirestoreService.loadAll();
      if (mounted) setState(() { _lists = lists; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalItems {
    int count = 0;
    for (final tl in _lists) {
      count += tl.unrankedItems.length;
      for (final t in tl.tiers) count += t.items.length;
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

  // Edit display name
  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _user?.displayName ?? '');
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
      await AuthService.updateDisplayName(result);
      setState(() {}); // Refresh to show new name
    }
  }

  // Sign out with confirmation
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.signOut();
      // AuthGate in main.dart will redirect to AuthScreen automatically
    }
  }

  // Upgrade guest → real account
  Future<void> _createAccount() async {
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    final nameCtrl  = TextEditingController();
    bool obscure = true;
    bool loading = false;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(builder: (c, setS) {
        return AlertDialog(
          title: const Text('Create Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create an account to back up your tier lists and access them on any device.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 chars)',
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setS(() => obscure = !obscure),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (emailCtrl.text.trim().isEmpty ||
                          passCtrl.text.length < 6) {
                        setS(() => error =
                            'Please enter a valid email and password (min 6 chars).');
                        return;
                      }
                      setS(() { loading = true; error = null; });
                      try {
                        await AuthService.linkGuestToEmail(
                          email: emailCtrl.text,
                          password: passCtrl.text,
                          displayName: nameCtrl.text,
                        );
                        if (c.mounted) Navigator.pop(c);
                        if (mounted) setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account created! Your data is now saved.'),
                              backgroundColor: AppColors.accent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setS(() {
                          loading = false;
                          error = AuthService.friendlyError(e);
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account'),
            ),
          ],
        );
      }),
    );
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
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? false;
    final displayName = isGuest
        ? 'Guest'
        : (user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.split('@').first ?? 'PeakPicker'));
    final initial = isGuest ? 'G' : (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar + Name
                    GestureDetector(
                      onTap: isGuest ? null : _editName,
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
                                initial,
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
                              Text(displayName,
                                  style: Theme.of(context).textTheme.headlineMedium),
                              if (!isGuest) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_rounded, size: 16,
                                    color: AppColors.textSecondary),
                              ],
                            ],
                          ),
                          if (!isGuest && user?.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                user!.email!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Guest banner
                    if (isGuest) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Text('You\'re browsing as a guest',
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ]),
                            const SizedBox(height: 6),
                            const Text(
                              'Your tier lists are saved locally. Create a free account to back them up and keep them safe.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _createAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                child: const Text('Create Free Account'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

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
                      ..._styleCounts.entries.map(
                          (e) => _buildStyleRow(e.key, e.value)),
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
                        child: Text(
                            'No tier lists yet. Create one to get started!',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    else
                      ..._lists.take(5).map((tl) => _buildRecentListTile(tl)),

                    const SizedBox(height: 32),

                    // Sign out button
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      label: const Text('Sign Out',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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
                  fontWeight: FontWeight.w600, fontSize: 14,
                  color: AppColors.textPrimary)),
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
              fontSize: 22, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
