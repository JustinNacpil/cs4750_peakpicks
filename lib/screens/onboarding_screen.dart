import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/peak_picks_logo.dart';

/// Dynamic walkthrough shown on first launch (and accessible later from Profile).
///
/// Implements the feedback report's "Dynamic Walkthrough for New Users" enhancement:
///   - Interactive onboarding through main features
///   - Skip and revisit options
///   - Visual icons demonstrating each feature
class OnboardingScreen extends StatefulWidget {
  /// When true, the user reached this screen from Profile → "View Walkthrough"
  /// (so we just pop instead of marking the first-launch flag).
  final bool fromSettings;

  /// Optional callback fired when the user finishes or skips the walkthrough.
  /// Used by the first-launch gate in main.dart, where there's no Navigator
  /// to pop back to.
  final VoidCallback? onFinish;

  const OnboardingScreen({
    super.key,
    this.fromSettings = false,
    this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.format_list_bulleted_rounded,
      title: 'Welcome to PeakPicks',
      body:
          'Rank everything that matters to you — movies, restaurants, games, '
          'gear, even your friends\' takes. Build beautiful tier lists in seconds.',
    ),
    _OnboardPage(
      icon: Icons.palette_rounded,
      title: 'Pick Your Style',
      body:
          'Choose from four ranking styles: Classic S-Tier, Worth It Scale, '
          'Slider Scale, or Bracket Battle. Each one fits a different way of thinking.',
    ),
    _OnboardPage(
      icon: Icons.add_photo_alternate_rounded,
      title: 'Add & Rank Items',
      body:
          'Tap "New List" to get started. Add picks with photos, drag them '
          'between tiers, and reorganize on the fly. Your changes save instantly.',
    ),
    _OnboardPage(
      icon: Icons.cloud_done_rounded,
      title: 'Synced Across Devices',
      body:
          'Sign in to back up your lists to the cloud and access them anywhere. '
          'Or continue as a guest — your data stays on this device.',
    ),
    _OnboardPage(
      icon: Icons.rocket_launch_rounded,
      title: 'You\'re All Set!',
      body:
          'You can revisit this walkthrough anytime from your Profile. '
          'Now go build your first list and rank everything.',
    ),
  ];

  Future<void> _finish() async {
    if (!widget.fromSettings) {
      await OnboardingService.markCompleted();
    }
    if (!mounted) return;
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: logo + skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  const PeakPicksLogo(height: 28),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      widget.fromSettings ? 'Close' : 'Skip',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardPage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(p.icon, size: 64, color: AppColors.accent),
          ),
          const SizedBox(height: 36),
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 16),
          Text(
            p.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}
