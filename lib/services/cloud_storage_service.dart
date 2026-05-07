import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Saves images locally on the device — no Firebase Storage needed (free tier).
/// Returns the local file path as a string, same interface as before.
class CloudStorageService {
  static Future<String> uploadItemImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(file.path).toLowerCase();
    final fileName = 'pp_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(p.join(dir.path, fileName));
    await file.copy(dest.path);
    return dest.path; // returns local path instead of a URL
  }

  static Future<void> deleteByUrl(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
