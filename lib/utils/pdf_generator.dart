import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/routine_entry.dart';
import '../models/exam_entry.dart';

class PdfGenerator {
  static const Map<String, int> _daysOrder = {
    'Saturday': 1,
    'Sunday': 2,
    'Monday': 3,
    'Tuesday': 4,
    'Wednesday': 5,
    'Thursday': 6,
    'Friday': 7,
  };

  static int _startTimeMinutes(String timeStr) {
    if (timeStr.isEmpty) return 9999;

    var startPart = timeStr.split('>>>>>').first.trim();
    startPart = startPart.replaceAll('.', ':');

    final parts = startPart.split(':');

    var hours = int.tryParse(parts[0]) ?? 0;
    final minutes =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (hours < 8) hours += 12;

    return hours * 60 + minutes;
  }

  static Future<({Uint8List bytes, String fileName})> build({
    required List<RoutineEntry> data,
    required String semesterText,
    required String department,
    required String sectionIdentifier,
  }) async {
    final sorted = [...data]
      ..sort((a, b) {
        final dayDiff =
            (_daysOrder[a.day] ?? 99).compareTo(_daysOrder[b.day] ?? 99);

        if (dayDiff != 0) return dayDiff;

        return _startTimeMinutes(a.time)
            .compareTo(_startTimeMinutes(b.time));
      });

    // Load university logo
    final logoBytes =
        (await rootBundle.load('assets/images/logo.png'))
            .buffer
            .asUint8List();

    final logo = pw.MemoryImage(logoBytes);

    final semesterNumber = semesterText.split(' ').first;

    final now = DateTime.now();

    final session = (now.month >= 1 && now.month <= 4)
        ? 'Spring'
        : (now.month >= 5 && now.month <= 8)
            ? 'Summer'
            : 'Fall';

    final year = now.year;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.only(
          left: 45,
          right: 45,
          top: 35,
          bottom: 35,
        ),

        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Center(
              child: pw.Image(
                logo,
                width: 70,
                height: 70,
              ),
            ),
          );

          widgets.add(
            pw.SizedBox(height: 18),
          );

          widgets.add(
            pw.Center(
              child: pw.Text(
                'Routine of $department ${semesterNumber} Semester $session $year',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          widgets.add(
            pw.SizedBox(height: 35),
          );

          String currentDay = '';

          for (final item in sorted) {
            if (currentDay != item.day) {
              currentDay = item.day;

              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12),
                  child: pw.Text(
                    currentDay,
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontSize: 16,
                      fontStyle: pw.FontStyle.italic,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              );

              widgets.add(
                pw.SizedBox(height: 12),
              );
            }            
             widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 2, bottom: 12),
                child: pw.Text(
                  '${item.time}   >>>>>   ${item.room}   >>>>>   ${item.facultyAcronym}   >>>>>   ${item.course}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    String fileName;

    if (sectionIdentifier != 'Combined_View' &&
        sectionIdentifier != 'Custom') {
      fileName = 'Routine_Sec_$sectionIdentifier.pdf';
    } else {
      fileName = 'Combined_Routine.pdf';
    }

    final bytes = await doc.save();

    return (
      bytes: bytes,
      fileName: fileName,
    );
  }

  //==================================================
  // Exam Schedule PDF
  //==================================================

  static int _dateSortKey(String date) {
    // Expected DD/MM/YYYY (or D/M/YYYY). Falls back to a large
    // number so unparsable dates sort last instead of crashing.
    final parts = date.split(RegExp(r'[>>>>>]'));
    if (parts.length != 3) return 99999999;

    final d = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final y = int.tryParse(parts[2]) ?? 0;

    return y * 10000 + m * 100 + d;
  }

  static Future<({Uint8List bytes, String fileName})> buildExamSchedule({
    required List<ExamEntry> data,
  }) async {
    final sorted = [...data]
      ..sort((a, b) {
        final dateDiff =
            _dateSortKey(a.date).compareTo(_dateSortKey(b.date));

        if (dateDiff != 0) return dateDiff;

        return _startTimeMinutes(a.time)
            .compareTo(_startTimeMinutes(b.time));
      });

    final logoBytes =
        (await rootBundle.load('assets/images/logo.png'))
            .buffer
            .asUint8List();

    final logo = pw.MemoryImage(logoBytes);

    // Derive session/year from the exam dates themselves rather than
    // "today", since an exam schedule can be uploaded well before or
    // after the exam period.
    String session = 'Summer';
    int year = DateTime.now().year;

    if (sorted.isNotEmpty) {
      final parts = sorted.first.date.split(RegExp(r'[/-]'));

      if (parts.length == 3) {
        final month = int.tryParse(parts[1]) ?? DateTime.now().month;
        year = int.tryParse(parts[2]) ?? year;

        session = (month >= 1 && month <= 4)
            ? 'Spring'
            : (month >= 5 && month <= 8)
                ? 'Summer'
                : 'Fall';
      }
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.only(
          left: 45,
          right: 45,
          top: 35,
          bottom: 35,
        ),

        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Center(
              child: pw.Image(
                logo,
                width: 70,
                height: 70,
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 18));

          widgets.add(
            pw.Center(
              child: pw.Text(
                'Exam Schedule >>>>> $session $year',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 35));

          String currentDate = '';

          for (final item in sorted) {
            final dateLabel =
                item.day.isNotEmpty ? '${item.date}  •  ${item.day}' : item.date;

            if (currentDate != item.date) {
              currentDate = item.date;

              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12),
                  child: pw.Text(
                    dateLabel,
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontSize: 16,
                      fontStyle: pw.FontStyle.italic,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              );

              widgets.add(pw.SizedBox(height: 12));
            }

            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 2, bottom: 12),
                child: pw.Text(
                  '${item.time}   >>>>>   ${item.course}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    final fileName = 'Exam_Schedule_$session$year.pdf';

    final bytes = await doc.save();

    return (
      bytes: bytes,
      fileName: fileName,
    );
  }
}