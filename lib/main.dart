import 'package:flutter/material.dart';
import 'screens/admin_screen.dart';
import 'screens/exam_schedule_screen.dart';
import 'screens/faculty_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/brand_app_bar.dart';

void main() {
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
      home: const RootShell(),
    );
  }
}

/// Hosts the two public pages (Home / Faculty Search) behind a bottom
/// navigation bar — the mobile equivalent of the `.navbar-links` in
/// index.html / faculty.html — plus a lock icon that opens the Admin
/// Upload screen (admin.html), which isn't linked from the web navbar
/// either.
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
    FacultyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        actions: [
          IconButton(
            tooltip: 'Admin Upload',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
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
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Faculty Search'),
        ],
      ),
    );
  }
}
