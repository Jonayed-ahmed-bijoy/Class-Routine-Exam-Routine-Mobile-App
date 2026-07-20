import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/course_file.dart';
import '../services/course_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

const List<String> _allowedExtensions = ['pdf', 'docx', 'pptx'];
const int _warnSizeBytes = 4 * 1024 * 1024; // 4 MB

class CourseFilesScreen extends StatefulWidget {
  final String uid;
  final String course;

  const CourseFilesScreen({
    super.key,
    required this.uid,
    required this.course,
  });

  @override
  State<CourseFilesScreen> createState() => _CourseFilesScreenState();
}

class _CourseFilesScreenState extends State<CourseFilesScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _busyFileId; // file currently being saved/deleted
  List<CourseFile> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final files = await CourseDataService.instance
          .listFiles(widget.uid, widget.course);
      setState(() => _files = files);
    } catch (e) {
      setState(() => _error = 'Failed to load files: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );

    if (result == null) return;

    final picked = result.files.single;
    if (picked.bytes == null) return;

    if (picked.bytes!.length > _warnSizeBytes) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Large File'),
          content: Text(
            'This file is ${(picked.bytes!.length / (1024 * 1024)).toStringAsFixed(1)} MB. '
            'Large files may be slow to upload/download. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _uploading = true);

    try {
      final extension = picked.extension ?? '';
      await CourseDataService.instance.uploadFile(
        uid: widget.uid,
        course: widget.course,
        fileName: picked.name,
        extension: extension,
        bytes: picked.bytes!,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveToDevice(CourseFile file) async {
    setState(() => _busyFileId = file.id);

    try {
      final full = await CourseDataService.instance
          .fetchFileWithData(widget.uid, widget.course, file.id);

      if (full.data == null) throw Exception('No file data found');

      final bytes = base64Decode(full.data!);

      await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${file.name}',
        fileName: file.name,
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyFileId = null);
    }
  }

  Future<void> _delete(CourseFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Remove "${file.name}"? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busyFileId = file.id);

    try {
      await CourseDataService.instance
          .deleteFile(widget.uid, widget.course, file.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyFileId = null);
    }
  }

  IconData _iconFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'docx':
        return Icons.description_outlined;
      case 'pptx':
        return Icons.slideshow_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.course} — Files')),
      body: Stack(
        children: [
          const BackgroundMesh(),
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload a file',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PDF, DOCX, or PPTX. Best for smaller lecture '
                        'notes/slides.',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _pickAndUpload,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(_uploading
                              ? 'Uploading...'
                              : 'Choose & Upload File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  )
                else if (_files.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No files yet for this course.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  for (final file in _files) ...[
                    GlassCard(
                      child: Row(
                        children: [
                          Icon(_iconFor(file.extension),
                              color: AppColors.accentPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  file.sizeLabel,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (_busyFileId == file.id)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            IconButton(
                              tooltip: 'Save to device',
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () => _saveToDevice(file),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _delete(file),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
