# PeakPicks – Tier List Mobile App

A clean, modern tier list maker built with Flutter. Create tier lists, rank items with images and descriptions, and choose between the **Worth It Scale** or **Classic S-Tier** styles.

## Features

- **Two tier styles**: Worth It Scale (Must Buy → Total Scam) and Classic S-Tier (S → F)
- **Drag & drop**: Long-press items to drag them between tiers
- **Image support**: Add photos from camera or gallery to each pick
- **Descriptions**: Tap any item to add a detailed explanation of why it's ranked where it is
- **Multiple lists**: Create and manage as many tier lists as you want
- **Local persistence**: All data saved on-device via SharedPreferences

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── theme/app_theme.dart          # Dark teal theme
├── models/tier_list.dart         # Data models
├── services/storage_service.dart # Local persistence
├── screens/
│   ├── home_screen.dart          # List of all tier lists
│   ├── create_tier_list_screen.dart  # New list wizard
│   ├── tier_list_editor_screen.dart  # Main editor with drag & drop
│   └── item_detail_screen.dart   # View/edit item details
└── widgets/
    └── tier_row.dart             # Tier row with drag target
```
