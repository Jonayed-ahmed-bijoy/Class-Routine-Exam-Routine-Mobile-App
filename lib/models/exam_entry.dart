/// One exam-slot row, matching the fields produced by upload.py's
/// parse_exam_schedule() (Date, Day, Time, Course).
class ExamEntry {
  final String date;
  final String day;
  final String time;
  final String course;

  const ExamEntry({
    required this.date,
    required this.day,
    required this.time,
    required this.course,
  });

  factory ExamEntry.fromJson(Map<String, dynamic> json) {
    return ExamEntry(
      date: (json['Date'] ?? '').toString(),
      day: (json['Day'] ?? '').toString(),
      time: (json['Time'] ?? '').toString(),
      course: (json['Course'] ?? '').toString(),
    );
  }
}

/// Firebase response for the exam schedule node.
class ExamScheduleResponse {
  final List<ExamEntry> data;
  final String? updatedAt;

  const ExamScheduleResponse({
    required this.data,
    required this.updatedAt,
  });
}
