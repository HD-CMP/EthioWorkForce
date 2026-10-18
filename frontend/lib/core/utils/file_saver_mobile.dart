import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndOpenFile(List<int> bytes, String filename) async {
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
