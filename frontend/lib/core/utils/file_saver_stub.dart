/// Stub — called by FileSaver.saveAndOpenFile via conditional import.
Future<String> platformSaveAndOpenFile(List<int> bytes, String filename) async {
  throw UnsupportedError('Cannot save file on this platform');
}
