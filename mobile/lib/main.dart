import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/api_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init();
  runApp(const ProjectFlowApp());
}

class ProjectFlowApp extends StatefulWidget {
  const ProjectFlowApp({super.key});

  static _ProjectFlowAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ProjectFlowAppState>();

  @override
  State<ProjectFlowApp> createState() => _ProjectFlowAppState();
}

class _ProjectFlowAppState extends State<ProjectFlowApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('fr');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await StorageService.getLocale();
    if (saved != null && mounted) {
      setState(() => _locale = Locale(saved));
    }
  }

  void setTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    StorageService.saveLocale(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProjectFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // Ecran de demarrage : initialise les ressources de l'app (ici, verifie la
  // session existante) pendant 2 a 3 secondes, puis redirige directement vers
  // le tableau de bord si l'utilisateur est deja connecte, sinon vers l'ecran
  // de connexion.
  Future<void> _bootstrap() async {
    final sessionCheck = StorageService.isLoggedIn();
    final minDelay = Future.delayed(const Duration(milliseconds: 2500));
    final results = await Future.wait([sessionCheck, minDelay]);
    final isLoggedIn = results[0] as bool;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.accent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Icon(Icons.analytics_rounded,
                  color: context.colors.accent, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('ProjectFlow',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text('Gestion de projets',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}