import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed the onboarding walkthrough.
class OnboardingService {
  static const _key = 'peakpicks_onboarding_completed_v1';

  /// Returns true if the user has already seen and completed/skipped the walkthrough.
  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// Mark walkthrough as completed (or skipped).
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Reset onboarding so the user can revisit it from settings.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
