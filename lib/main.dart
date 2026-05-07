import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PeakPicksApp());
}

class PeakPicksApp extends StatelessWidget {
  const PeakPicksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeakPicks',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

/// Listens to Firebase auth state and routes accordingly.
/// On first launch, shows the onboarding walkthrough before the auth screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkedOnboarding = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final completed = await OnboardingService.hasCompleted();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !completed;
      _checkedOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wait until we know whether to show onboarding
    if (!_checkedOnboarding) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // First launch → walkthrough, then auth
    if (_showOnboarding) {
      return OnboardingScreen(
        onFinish: () {
          if (mounted) setState(() => _showOnboarding = false);
        },
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state, show splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Logged in → home
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        // Not logged in → auth
        return const AuthScreen();
      },
    );
  }
}
