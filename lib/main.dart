import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/exam_schedule_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/task_screen.dart';
import 'screens/upload_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/brand_app_bar.dart';

void main() {
  // Prevents google_fonts from trying to download font files over the
  // network at runtime. Without this, a slow/unstable/blocked network
  // connection (e.g. switching WiFi, a locked-down campus network) can
  // throw the SocketException seen above. With this set, it silently
  // falls back to a bundled system font instead — the app never
  // depends on reaching fonts.gstatic.com to render text.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const EduRoutineApp());
}

class EduRoutineApp extends StatelessWidget {
  const EduRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Routine App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

/// Restores a saved login session (if any) before deciding whether to
/// show the Login screen or go straight into the app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await AuthService.instance.loadSession();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AuthService.instance.isLoggedIn
        ? const RootShell()
        : const LoginScreen();
  }
}

/// Hosts the app's main pages (Home / Exams / Faculty Search) behind a
/// bottom navigation bar, plus an upload icon (each user's own private
/// upload) and a logout icon.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    ExamScheduleScreen(),
    DashboardScreen(),
    TaskScreen(),
  ];

  Future<void> _logout() async {
    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        actions: [
          IconButton(
            tooltip: 'Upload My Routine',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UploadScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Exams'),
          BottomNavigationBarItem(
              icon: Icon(Icons.today_outlined),
              activeIcon: Icon(Icons.today),
              label: 'Today'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist),
              label: 'Task'),
        ],
      ),
    );
  }
}
