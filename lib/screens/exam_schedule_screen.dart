import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/exam_entry.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_generator.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  StatusKind _statusKind = StatusKind.loading;
  String _statusText = 'Connecting to database...';

  List<ExamEntry> _examData = [];
  final Set<String> _uniqueCourses = {};
  final Set<String> _selectedCourses = {};

  final _courseController = TextEditingController();
  List<String> _suggestions = [];

  bool _exporting = false;

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
      final result = await ApiService.instance.fetchExamSchedule();

      if (result.data.isEmpty) {
        setState(() {
          _examData = [];
          _statusKind = StatusKind.error;
          _statusText = 'No exam schedule uploaded yet. Contact CR.';
        });
        return;
      }

      _uniqueCourses.clear();
      for (final item in result.data) {
        if (item.course.isNotEmpty) {
          _uniqueCourses.add(item.course);
          if (item.course.contains('.')) {
            _uniqueCourses.add(item.course.split('.').first);
          }
        }
      }

      final dateStr = result.updatedAt != null
          ? (DateTime.tryParse(result.updatedAt!)
                  ?.toLocal()
                  .toString()
                  .split(' ')
                  .first ??
              'Unknown')
          : 'Unknown';

      setState(() {
        _examData = result.data;
        _statusKind = StatusKind.live;
        _statusText = 'Live Exam Schedule (Updated: $dateStr)';
      });
    } catch (e) {
      setState(() {
        _statusKind = StatusKind.error;
        _statusText = 'Connection Error. Check internet.';
      });
    }
  }

  bool get _dataReady => _statusKind == StatusKind.live;

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

  // A selected course matches either an exact entry (e.g. "CSE 111"
  // matching an entry literally coded "CSE 111") or a sectioned one
  // (e.g. "CSE 111" also pulling in "CSE 111.1", "CSE 111.2", etc.).
  List<ExamEntry> get _filteredData {
    if (_selectedCourses.isEmpty) return _examData;

    return _examData.where((e) {
      return _selectedCourses.any((sel) =>
          e.course == sel || e.course.startsWith('$sel.'));
    }).toList();
  }

  Map<String, List<ExamEntry>> _groupByDate(List<ExamEntry> entries) {
    final map = <String, List<ExamEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    return map;
  }

  Future<void> _exportPdf() async {
    if (_selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one course first')),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final result = await PdfGenerator.buildExamSchedule(
        data: _filteredData,
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
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_filteredData);

    return Stack(
      children: [
        const BackgroundMesh(),
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Center(child: StatusBadge(kind: _statusKind, text: _statusText)),
              const SizedBox(height: 20),

              if (_statusKind == StatusKind.live) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your Courses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                    labelStyle: const TextStyle(
                                        color: AppColors.textPrimary),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 16),
                                    deleteIconColor: AppColors.textSecondary,
                                    onDeleted: () => _removeCourse(c),
                                    side: const BorderSide(
                                        color: AppColors.borderSubtle),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              (_exporting || _selectedCourses.isEmpty)
                                  ? null
                                  : _exportPdf,
                          icon: _exporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(_exporting
                              ? 'Generating...'
                              : 'Download PDF for Selected Courses'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                            disabledBackgroundColor: AppColors.bgCardHover,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_selectedCourses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Showing the full exam schedule.\nSelect courses above to filter it down to just yours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),

                for (final entry in grouped.entries) ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_outlined,
                                size: 18, color: AppColors.accentPrimary),
                            const SizedBox(width: 8),
                            Text(
                              entry.value.first.day.isNotEmpty
                                  ? '${entry.key}  •  ${entry.value.first.day}'
                                  : entry.key,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final e in entry.value)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    e.time,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.course,
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
