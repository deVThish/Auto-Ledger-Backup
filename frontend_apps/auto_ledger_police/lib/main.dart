import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_routes.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/biometric_auth_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/divisional_officer/screens/do_dashboard_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/traffic_officer/screens/to_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AutoLedgerPoliceApp());
}

class AutoLedgerPoliceApp extends StatelessWidget {
  const AutoLedgerPoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto-Ledger Police',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SessionGate(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.divisionalDashboard: (_) => const DoDashboardScreen(),
        AppRoutes.trafficOfficerDashboard: (_) => const ToDashboardScreen(),
      },
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final TokenStorage _tokenStorage = const TokenStorage();
  bool _isLoading = true;
  Widget _screen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Widget _dashboardForRole(String role) {
    if (role == 'DIVISIONAL_HEAD') {
      return const DoDashboardScreen();
    }
    if (role == 'TRAFFIC_OFFICER') {
      return const ToDashboardScreen();
    }
    return const LoginScreen();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;

      if (!hasSeenTutorial && mounted) {
        setState(() {
          _screen = const OnboardingScreen();
          _isLoading = false;
        });
        return;
      }

      final session = await _tokenStorage.getSession();
      if (!mounted) return;

      if (session == null) {
        setState(() {
          _screen = const LoginScreen();
          _isLoading = false;
        });
        return;
      }

      final targetScreen = _dashboardForRole(session.role);
      final biometricEnabled = await _tokenStorage.getBiometricEnabled();

      if (!mounted) return;

      if (biometricEnabled) {
        setState(() {
          _screen = BiometricAuthScreen(nextScreen: targetScreen);
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _screen = targetScreen;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _screen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _SplashScreen();
    }
    return _screen;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlack,
        ),
      ),
    );
  }
}