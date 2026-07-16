import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

enum _UploadState {
  idle,
  uploading,
  success,
  error,
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  Uint8List? _pickedBytes;
  String? _pickedFileName;

  _UploadState _state = _UploadState.idle;
  String _statusMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;

      if (file.bytes != null) {
        setState(() {
          _pickedBytes = file.bytes!;
          _pickedFileName = file.name;
        });
      }
    }
  }

  Future<void> _upload() async {
    if (_passwordController.text.trim().isEmpty) {
      _showAlert("Enter admin password");
      return;
    }

    if (_pickedBytes == null) {
      _showAlert("Choose a DOCX file first");
      return;
    }

    setState(() {
      _state = _UploadState.uploading;
      _statusMessage = "Uploading routine...";
    });

    try {
      final response = await ApiService.instance.uploadRoutine(
        fileBytes: _pickedBytes!,
        fileName: _pickedFileName!,
        password: _passwordController.text.trim(),
      );

      final detectedType = response['type'] == 'exam_schedule'
          ? 'Exam Schedule'
          : 'Class Routine';

      setState(() {
        _state = _UploadState.success;
        _statusMessage =
            "✅ Detected as: $detectedType — uploaded successfully";
      });
    } catch (e) {
      setState(() {
        _state = _UploadState.error;
        _statusMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void _showAlert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (_state) {
      case _UploadState.success:
        return Colors.green;

      case _UploadState.error:
        return Colors.red;

      case _UploadState.uploading:
        return Colors.orange;

      case _UploadState.idle:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploading = _state == _UploadState.uploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Upload"),
      ),
      body: Stack(
        children: [
          const BackgroundMesh(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🔒 Admin Upload",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text("Admin Password"),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Enter admin password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text("Routine File (.docx)"),

                      const SizedBox(height: 8),

                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.upload_file),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  _pickedFileName ??
                                      "Choose DOCX Routine File",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: uploading ? null : _upload,
                          child: uploading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("Upload & Update"),
                        ),
                      ),

                      if (_statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}