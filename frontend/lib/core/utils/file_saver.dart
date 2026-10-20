import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_mobile.dart';

class FileSaver {
  /// Saves bytes to a file and returns a descriptive message.
  /// Delegates to the platform-specific top-level function.
  static Future<String> saveAndOpenFile(List<int> bytes, String filename) =>
      platformSaveAndOpenFile(bytes, filename);
}
