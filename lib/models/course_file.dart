/// A file (PDF/DOCX/PPTX/etc.) a student attached to a specific course.
/// Stored base64-encoded directly in Firebase Realtime Database under
/// /users/{uid}/files/{courseKey}/{fileId}.
///
/// Note: Firebase Realtime Database isn't built for large binary blobs.
/// This works well for lecture notes / slides in the low single-digit
/// MB range, but isn't meant for large video-heavy files.
class CourseFile {
  final String id;
  final String name;
  final String extension;
  final int sizeBytes;
  final String uploadedAt;
  final String? data; // base64, only populated when actually downloading

  const CourseFile({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.uploadedAt,
    this.data,
  });

  factory CourseFile.fromJson(String id, Map<String, dynamic> json) {
    return CourseFile(
      id: id,
      name: (json['name'] ?? 'file').toString(),
      extension: (json['extension'] ?? '').toString(),
      sizeBytes: (json['size'] is int)
          ? json['size'] as int
          : int.tryParse('${json['size']}') ?? 0,
      uploadedAt: (json['uploadedAt'] ?? '').toString(),
      data: json['data']?.toString(),
    );
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
