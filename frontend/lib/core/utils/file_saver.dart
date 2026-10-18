import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_mobile.dart';

class FileSaver {
  static Future<String> saveAndOpenFile(List<int> bytes, String filename) {
    return saveAndOpenFile(bytes, filename);
  }
}
