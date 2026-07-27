import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerService {
  static const List<String> allowedExtensions = ['m4a', 'wav', 'aac', 'mp3', 'ogg', 'flac'];
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

  /// Open device file picker and validate format and size.
  Future<FilePickerResultInfo?> pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final platformFile = result.files.first;
    final path = platformFile.path;

    if (path == null) {
      throw Exception('Failed to access file path.');
    }

    final extension = platformFile.extension?.toLowerCase() ?? path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Unsupported audio format (.$extension). Allowed formats: ${allowedExtensions.join(', ')}.');
    }

    final size = platformFile.size;
    if (size > maxFileSizeBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      throw Exception('File size ($sizeMb MB) exceeds the maximum limit of 20 MB.');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Selected file does not exist on device.');
    }

    return FilePickerResultInfo(
      path: path,
      name: platformFile.name,
      sizeBytes: size,
      extension: extension,
    );
  }
}

class FilePickerResultInfo {
  final String path;
  final String name;
  final int sizeBytes;
  final String extension;

  FilePickerResultInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.extension,
  });
}
