import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Top-level function — called by FileSaver.saveAndOpenFile via conditional import.
Future<String> platformSaveAndOpenFile(List<int> bytes, String filename) async {
  Directory? directory;
  try {
    directory = await getDownloadsDirectory();
  } catch (_) {
    directory = null;
  }
  directory ??= await getApplicationDocumentsDirectory();

  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return 'Saved to ${file.path}';
}
