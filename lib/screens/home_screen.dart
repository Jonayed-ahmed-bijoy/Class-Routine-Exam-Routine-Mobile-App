import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/routine_entry.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_generator.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

const List<String> _semesters = [
  '1st Semester',
  '2nd Semester',
  '3rd Semester',
  '4th Semester',
  '5th Semester',
  '6th Semester',
  '7th Semester',
  '8th Semester',
  '9th Semester',
  '10th Semester',
  '11th Semester',
  '12th Semester',
];

const Map<String, String> _departments = {
  'CSE': 'CSE — Computer Science & Engineering',
  'EEE': 'EEE — Electrical & Electronic Engineering',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StatusKind _statusKind = StatusKind.loading;
  String _statusText = 'Connecting to database...';

  List<RoutineEntry> _routineData = [];
  final Set<String> _uniqueCourses = {};
  final Set<String> _selectedCourses = {};


  final _courseController = TextEditingController();
  List<String> _suggestions = [];

  String? _semester;
  String? _department;

  bool _generating = false;
  List<GeneratedRoutine>? _primary;
  List<GeneratedRoutine>? _secondary;
  bool _noMatches = false;
  final Set<String> _exportingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _statusKind = StatusKind.loading;
      _statusText = 'Connecting to database...';
    });

    try {
      final result = await ApiService.instance.fetchRoutine();

      if (result.data.isEmpty) {
        setState(() {
          _statusKind = StatusKind.error;
          _statusText = 'No routine uploaded yet. Contact CR.';
        });
        return;
      }

      _routineData = result.data;


      _uniqueCourses.clear();
      for (final item in _routineData) {
        if (item.course.isNotEmpty) {
          _uniqueCourses.add(item.course);
          if (item.course.contains('.')) {
            _uniqueCourses.add(item.course.split('.').first);
          }
        }
      }

      final dateStr = result.updatedAt != null
          ? (DateTime.tryParse(result.updatedAt!)?.toLocal().toString().split(' ').first ??
              'Unknown')
          : 'Unknown';

      setState(() {
        _statusKind = StatusKind.live;
        _statusText = 'Live Routine (Updated: $dateStr)';
      });
    } catch (e) {
      setState(() {
        _statusKind = StatusKind.error;
        _statusText = 'Connection Error. Check internet.';
      });
    }
  }

  bool get _dataReady =>
      _statusKind == StatusKind.live;

  bool get _canGenerate =>
      _selectedCourses.isNotEmpty && _semester != null && _department != null;

  void _onSearchChanged(String value) {
    final query = value.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final matches = _uniqueCourses
        .where((c) => c.toUpperCase().contains(query))
        .toList()
      ..sort((a, b) => a.compareTo(b));
    setState(() => _suggestions = matches.take(10).toList());
  }

  void _selectCourse(String course) {
    setState(() {
      _selectedCourses.add(course);
      _courseController.clear();
      _suggestions = [];
    });
  }

  void _removeCourse(String course) {
    setState(() => _selectedCourses.remove(course));
  }

  /// Direct port of generateRoutines() in script.js.
  void _generateRoutines() {
    setState(() {
      _generating = true;
      _primary = null;
      _secondary = null;
      _noMatches = false;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      final semesterText = _semester!;
      final department = _department!;

      final sectionMap = <String, List<RoutineEntry>>{};
      var customRoutineData = <RoutineEntry>[];

      for (final courseStr in _selectedCourses) {
        final exactMatches =
            _routineData.where((r) => r.course == courseStr).toList();

        if (exactMatches.isNotEmpty) {
          customRoutineData.addAll(exactMatches);
        } else {
          final childRows = _routineData
              .where((r) => r.course.startsWith('$courseStr.'))
              .toList();
          for (final row in childRows) {
            final section = row.course.split('.')[1];
            sectionMap.putIfAbsent(section, () => []).add(row);
          }
        }
      }

      // Auto-merge: if the custom selection resolves to exactly one
      // section, fold it into that section instead of a separate group.
      if (customRoutineData.isNotEmpty) {
        final uniqueCustomRows = customRoutineData.toSet().toList();
        final sectionsFound = <String>{};
        for (final row in uniqueCustomRows) {
          if (row.course.contains('.')) {
            sectionsFound.add(row.course.split('.')[1]);
          }
        }
        if (sectionsFound.length == 1) {
          final targetSection = sectionsFound.first;
          sectionMap.putIfAbsent(targetSection, () => []).addAll(uniqueCustomRows);
          customRoutineData = [];
        }
      }

      final routinesToRender = <GeneratedRoutine>[];

      if (customRoutineData.isNotEmpty) {
        final uniqueRows = customRoutineData.toSet().toList();
        routinesToRender.add(GeneratedRoutine(
          id: 'Custom',
          data: uniqueRows,
          count: uniqueRows.map((r) => r.course).toSet().length,
          type: 'Custom',
        ));
      }

      sectionMap.forEach((sectionID, rows) {
        final uniqueRows = rows.toSet().toList();
        routinesToRender.add(GeneratedRoutine(
          id: sectionID,
          data: uniqueRows,
          count: uniqueRows.map((r) => r.course).toSet().length,
          type: 'Section',
        ));
      });

      if (routinesToRender.isEmpty) {
        setState(() {
          _generating = false;
          _noMatches = true;
        });
        return;
      }

      final maxCount =
          routinesToRender.map((r) => r.count).reduce((a, b) => a > b ? a : b);
      final threshold = maxCount > 1 ? maxCount - 1 : 1;

      final primary = routinesToRender.where((r) => r.count >= threshold).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final secondary = routinesToRender.where((r) => r.count < threshold).toList()
        ..sort((a, b) {
          final c = b.count.compareTo(a.count);
          if (c != 0) return c;
          return a.id.compareTo(b.id);
        });

      setState(() {
        _primary = primary;
        _secondary = secondary;
        _generating = false;
      });

      // Stash for PDF export (semester text/department needed there too)
      _lastSemesterText = semesterText;
      _lastDepartment = department;
    });
  }

  String _lastSemesterText = '';
  String _lastDepartment = '';

  Future<void> _exportPdf(GeneratedRoutine routine) async {
    setState(() => _exportingIds.add(routine.id));
    try {
      final result = await PdfGenerator.build(
        data: routine.data,
        semesterText: _lastSemesterText,
        department: _lastDepartment,
        sectionIdentifier: routine.id,

      );
      await Printing.sharePdf(
        bytes: result.bytes,
        filename: result.fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingIds.remove(routine.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundMesh(),
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const _PageHeader(
                title: 'CLASS ROUTINE APP',
                subtitle:
                    'An easy way to get your semester routine',
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(kind: _statusKind, text: _statusText),
                    const SizedBox(height: 20),
                    _StepLabel(number: '1', label: 'Search Courses'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _courseController,
                      enabled: _dataReady,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Type course code (e.g. CSE 317)...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted, size: 20),
                      ),
                    ),
                    if (_suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgCardHover,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, i) {
                            final course = _suggestions[i];
                            return ListTile(
                              dense: true,
                              title: Text(course,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary)),
                              onTap: () => _selectCourse(course),
                            );
                          },
                        ),
                      ),
                    if (_selectedCourses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCourses
                            .map((c) => Chip(
                                  label: Text(c),
                                  backgroundColor: AppColors.bgCardHover,
                                  labelStyle:
                                      const TextStyle(color: AppColors.textPrimary),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  deleteIconColor: AppColors.textSecondary,
                                  onDeleted: () => _removeCourse(c),
                                  side: const BorderSide(
                                      color: AppColors.borderSubtle),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _StepLabel(number: '2', label: 'Select Semester'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _semester,
                      dropdownColor: AppColors.bgCardHover,
                      hint: const Text('Choose a semester',
                          style: TextStyle(color: AppColors.textMuted)),
                      items: _semesters
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _semester = v),
                    ),
                    const SizedBox(height: 20),
                    _StepLabel(number: '3', label: 'Select Department'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _department,
                      isExpanded: true,
                      dropdownColor: AppColors.bgCardHover,
                      hint: const Text('Choose a department',
                          style: TextStyle(color: AppColors.textMuted)),
                      items: _departments.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                overflow: TextOverflow.ellipsis,
                              )))
                          .toList(),
                      onChanged: (v) => setState(() => _department = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_canGenerate && !_generating) ? _generateRoutines : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          disabledBackgroundColor: AppColors.bgCardHover,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_generating ? 'Generating...' : 'Generate Routine'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Generated Routine',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    if (_generating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.accentPrimary),
                              SizedBox(height: 12),
                              Text('Generating your routine...',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else if (_noMatches)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No matching classes found in data.',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      )
                    else if (_primary == null && _secondary == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Your PDF download links will appear here.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    else ...[
                      if (_primary!.isNotEmpty && _secondary!.isNotEmpty)
                        const _SectionHeader(label: 'Main Sections'),
                      ..._primary!.map(_buildRoutineTile),
                      if (_secondary!.isNotEmpty) ...[
                        if (_primary!.isNotEmpty)
                          const _SectionHeader(
                              label: 'Partial / Extra Lab Sections'),
                        ..._secondary!.map(_buildRoutineTile),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineTile(GeneratedRoutine routine) {
    final label = routine.id == 'Custom'
        ? 'Custom Routine'
        : 'Section ${routine.id}';
    final isExporting = _exportingIds.contains(routine.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.bgCardHover,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isExporting ? null : () => _exportPdf(routine),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text('📄', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ),
                if (isExporting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.download_rounded,
                      color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              gradient: AppColors.logoGradient, shape: BoxShape.circle),
          child: Text(number,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }
}
