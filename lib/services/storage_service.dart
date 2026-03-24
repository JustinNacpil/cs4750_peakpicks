import 'package:shared_preferences/shared_preferences.dart';
import '../models/tier_list.dart';

class StorageService {
  static const _key = 'peakpicks_tier_lists';

  static Future<List<TierList>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw.map((s) => TierList.decode(s)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> saveAll(List<TierList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, lists.map((l) => l.encode()).toList());
  }

  static Future<void> saveSingle(TierList tl) async {
    final all = await loadAll();
    final idx = all.indexWhere((l) => l.id == tl.id);
    if (idx >= 0) {
      all[idx] = tl;
    } else {
      all.insert(0, tl);
    }
    await saveAll(all);
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((l) => l.id == id);
    await saveAll(all);
  }
}
