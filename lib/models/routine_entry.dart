/// One class-slot row, matching the fields produced by upload.py
/// (Day, Time, Room, Course, FacultyAcronym, FacultyFullName, Type).
class RoutineEntry {
  final String day;
  final String time;
  final String room;
  final String course;
  final String facultyAcronym;
  final String facultyFullName;
  final String type;

  const RoutineEntry({
    required this.day,
    required this.time,
    required this.room,
    required this.course,
    required this.facultyAcronym,
    required this.facultyFullName,
    required this.type,
  });

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    return RoutineEntry(
      day: (json['Day'] ?? '').toString(),
      time: (json['Time'] ?? '').toString(),
      room: (json['Room'] ?? '').toString(),
      course: (json['Course'] ?? '').toString(),
      facultyAcronym: (json['FacultyAcronym'] ?? '').toString(),
      facultyFullName: (json['FacultyFullName'] ?? '').toString(),
      type: (json['Type'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RoutineEntry &&
          other.day == day &&
          other.time == time &&
          other.room == room &&
          other.course == course &&
          other.facultyAcronym == facultyAcronym &&
          other.facultyFullName == facultyFullName &&
          other.type == type;

  @override
  int get hashCode => Object.hash(
    day,
    time,
    room,
    course,
    facultyAcronym,
    facultyFullName,
    type,
  );
}

/// Generated Routine
class GeneratedRoutine {
  final String id;
  final List<RoutineEntry> data;
  final int count;
  final String type;

  const GeneratedRoutine({
    required this.id,
    required this.data,
    required this.count,
    required this.type,
  });
}

/// Firebase Response
class RoutineResponse {
  final List<RoutineEntry> data;
  final String? updatedAt;

  const RoutineResponse({
    required this.data,
    required this.updatedAt,
  });
}