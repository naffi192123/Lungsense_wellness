import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FilePickerService {
  static const List<String> allowedExtensions = ['m4a', 'wav', 'aac', 'mp3', 'ogg', 'flac'];
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

  /// Open device file picker and validate format and size.
  /// Handles iOS/macOS sandboxed file selection and byte-caching when path is virtual.
  Future<FilePickerResultInfo?> pickAudioFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true,
      );
    } on PlatformException catch (pe) {
      if (pe.code == 'ENTITLEMENT_NOT_FOUND') {
        throw Exception('File access permission is required on this device. Please ensure file access permissions are enabled in settings.');
      }
      throw Exception('Could not open file picker: ${pe.message ?? pe.code}');
    }

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final platformFile = result.files.first;
    String? path = platformFile.path;

    // On iOS, selecting files from cloud/Files app may result in a null path.
    // In that case, persist the in-memory bytes into a temporary local file.
    if ((path == null || path.isEmpty) && platformFile.bytes != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final sanitizedName = platformFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final cachedFile = File('${tempDir.path}/picked_$sanitizedName');
        await cachedFile.writeAsBytes(platformFile.bytes!);
        path = cachedFile.path;
      } catch (_) {}
    }

    if (path == null || path.isEmpty) {
      throw Exception('Failed to access file path. Please try selecting the file again.');
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
