import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ──────────────────────────────────────────────
//  Tier Style Presets
// ──────────────────────────────────────────────

enum TierStyleType { worthIt, classic, slider, bracket }

class TierPreset {
  final String label;
  final int colorValue;
  TierPreset({required this.label, required this.colorValue});

  Map<String, dynamic> toJson() => {'label': label, 'colorValue': colorValue};
  factory TierPreset.fromJson(Map<String, dynamic> j) =>
      TierPreset(label: j['label'], colorValue: j['colorValue']);
}

List<TierPreset> worthItPresets = [
  TierPreset(label: 'MUST BUY', colorValue: 0xFFE53935),
  TierPreset(label: 'WORTH IT', colorValue: 0xFFFB8C00),
  TierPreset(label: 'EH, OKAY', colorValue: 0xFFFDD835),
  TierPreset(label: 'NOT WORTH', colorValue: 0xFF66BB6A),
  TierPreset(label: 'TOTAL SCAM', colorValue: 0xFF42A5F5),
];

List<TierPreset> classicPresets = [
  TierPreset(label: 'S', colorValue: 0xFFE53935),
  TierPreset(label: 'A', colorValue: 0xFFFB8C00),
  TierPreset(label: 'B', colorValue: 0xFFFDD835),
  TierPreset(label: 'C', colorValue: 0xFF66BB6A),
  TierPreset(label: 'D', colorValue: 0xFF42A5F5),
  TierPreset(label: 'F', colorValue: 0xFF7E57C2),
];

List<TierPreset> sliderPresets = [
  TierPreset(label: 'Amazing', colorValue: 0xFFE53935),
  TierPreset(label: 'Good', colorValue: 0xFFFB8C00),
  TierPreset(label: 'Meh', colorValue: 0xFFFDD835),
  TierPreset(label: 'Bad', colorValue: 0xFF66BB6A),
  TierPreset(label: 'Never', colorValue: 0xFF42A5F5),
];

List<TierPreset> bracketPresets = [
  TierPreset(label: 'CHAMPION', colorValue: 0xFFFFD700),
  TierPreset(label: 'RUNNER-UP', colorValue: 0xFFC0C0C0),
  TierPreset(label: 'SEMI-FINAL', colorValue: 0xFFCD7F32),
  TierPreset(label: 'ELIMINATED', colorValue: 0xFF78909C),
];

// ──────────────────────────────────────────────
//  Data Models
// ──────────────────────────────────────────────

class TierItem {
  String id;
  String name;
  String description;
  String? imagePath;   // local file path (device cache)
  String? imageUrl;    // local path or cloud URL
  DateTime createdAt;

  TierItem({
    String? id,
    required this.name,
    this.description = '',
    this.imagePath,
    this.imageUrl,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  /// The best image source to display: prefer cloud URL, fallback to local path.
  String? get displayImage => imageUrl ?? imagePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TierItem.fromJson(Map<String, dynamic> j) => TierItem(
        id: j['id'],
        name: j['name'],
        description: j['description'] ?? '',
        imagePath: j['imagePath'],
        imageUrl: j['imageUrl'],
        createdAt: DateTime.parse(j['createdAt']),
      );

  // Firestore-compatible map (same as toJson but explicit)
  Map<String, dynamic> toFirestore() => toJson();

  factory TierItem.fromFirestore(Map<String, dynamic> j) =>
      TierItem.fromJson(j);
}

class Tier {
  String id;
  String label;
  int colorValue;
  List<TierItem> items;

  Tier({
    String? id,
    required this.label,
    required this.colorValue,
    List<TierItem>? items,
  })  : id = id ?? _uuid.v4(),
        items = items ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'colorValue': colorValue,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Tier.fromJson(Map<String, dynamic> j) => Tier(
        id: j['id'],
        label: j['label'],
        colorValue: j['colorValue'],
        items: (j['items'] as List).map((i) => TierItem.fromJson(i)).toList(),
      );
}

/// Bracket matchup for bracket-style tier lists
class BracketMatchup {
  String id;
  String item1Id;
  String item2Id;
  String? winnerId; // null = not yet decided
  int round;

  BracketMatchup({
    String? id,
    required this.item1Id,
    required this.item2Id,
    this.winnerId,
    required this.round,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'item1Id': item1Id,
        'item2Id': item2Id,
        'winnerId': winnerId,
        'round': round,
      };

  factory BracketMatchup.fromJson(Map<String, dynamic> j) => BracketMatchup(
        id: j['id'],
        item1Id: j['item1Id'],
        item2Id: j['item2Id'],
        winnerId: j['winnerId'],
        round: j['round'],
      );
}

class TierList {
  String id;
  String title;
  String description;
  TierStyleType styleType;
  List<Tier> tiers;
  List<TierItem> unrankedItems;
  List<BracketMatchup> bracketMatchups;
  DateTime createdAt;
  DateTime updatedAt;
  String? userId; // Firebase Auth UID

  TierList({
    String? id,
    required this.title,
    this.description = '',
    required this.styleType,
    required this.tiers,
    List<TierItem>? unrankedItems,
    List<BracketMatchup>? bracketMatchups,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  })  : id = id ?? _uuid.v4(),
        unrankedItems = unrankedItems ?? [],
        bracketMatchups = bracketMatchups ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'styleType': styleType.index,
        'tiers': tiers.map((t) => t.toJson()).toList(),
        'unrankedItems': unrankedItems.map((i) => i.toJson()).toList(),
        'bracketMatchups': bracketMatchups.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (userId != null) 'userId': userId,
      };

  factory TierList.fromJson(Map<String, dynamic> j) => TierList(
        id: j['id'],
        title: j['title'],
        description: j['description'] ?? '',
        styleType: TierStyleType.values[j['styleType']],
        tiers: (j['tiers'] as List).map((t) => Tier.fromJson(t)).toList(),
        unrankedItems: (j['unrankedItems'] as List?)
                ?.map((i) => TierItem.fromJson(i))
                .toList() ??
            [],
        bracketMatchups: (j['bracketMatchups'] as List?)
                ?.map((m) => BracketMatchup.fromJson(m))
                .toList() ??
            [],
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        userId: j['userId'],
      );

  /// Find a TierItem by id across all tiers and unranked
  TierItem? findItem(String itemId) {
    for (final t in tiers) {
      for (final i in t.items) {
        if (i.id == itemId) return i;
      }
    }
    for (final i in unrankedItems) {
      if (i.id == itemId) return i;
    }
    return null;
  }

  /// Get all items (ranked + unranked)
  List<TierItem> get allItems {
    final list = <TierItem>[];
    for (final t in tiers) {
      list.addAll(t.items);
    }
    list.addAll(unrankedItems);
    return list;
  }

  String encode() => jsonEncode(toJson());
  static TierList decode(String s) => TierList.fromJson(jsonDecode(s));
}
