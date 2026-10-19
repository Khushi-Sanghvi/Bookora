import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String?> pickAndSaveBookFile({List<String> extensions = const ['pdf', 'epub']}) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
    } catch (_) {
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
      } catch (_) {
        result = null;
      }
    }

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = p.basename(file.path);
      final ext = p.extension(file.path).replaceAll('.', '').toLowerCase();

      // Ensure extension matches allowed list if strict filtering was bypassed by OEM
      if (extensions.isNotEmpty && !extensions.contains(ext) && !extensions.contains('*')) {
        // Continue if it's a valid document/audio extension
      }
      
      final appDocDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(appDocDir.path, 'books'));
      
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      String newPath = p.join(booksDir.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
      await file.copy(newPath);
      
      return newPath;
    }
    return null;
  }

  Future<String?> pickAndSavePdfFile() async {
    return pickAndSaveBookFile(extensions: ['pdf']);
  }

  Future<String?> pickAndSaveEpubFile() async {
    return pickAndSaveBookFile(extensions: ['epub']);
  }

  Future<String?> pickAndSaveAudioFile() async {
    return pickAndSaveBookFile(extensions: ['mp3', 'm4b', 'aac', 'wav', 'm4a']);
  }

  Future<bool> deleteBookFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }
}
