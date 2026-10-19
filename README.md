<div align="center">

# 📖 Bookora

### *An Enchanting Sanctuary for Bibliophiles, Readers & Collectors*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)]()
[![Theme](https://img.shields.io/badge/Aesthetic-Dark%20Academia-8B5A2B)]()
[![Release](https://img.shields.io/badge/Release-v1.0.0-amber?logo=github)](https://github.com/Khushi-Sanghvi/Bookora/releases/tag/v1.0.0)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*Step beyond ordinary reading trackers. Bookora is a handcrafted digital library, intelligent e-reader, and literary companion tailored for readers who cherish the atmospheric romance of literature, physical book aesthetics, and deep story immersion.*

---

[Key Features](#-key-features) • [Aesthetics](#-dark-academia-aesthetic) • [Story Codex](#-the-story-codex-engine) • [Installation](#-getting-started) • [Download](#-download-latest-release)

</div>

---

## ✨ Overview

**Bookora** transforms how you organize, experience, and preserve your reading life. Combining physical book charm with modern digital convenience, Bookora offers custom ePub & PDF rendering, ambient reading modes, rich literary narrative analysis, audiobook playback, and dual-view habit tracking—wrapped in a lavish **Dark Academia** palette.

---

## 🌟 Key Features

### 📚 Versatile Atmospheric Library Layouts
Display your library exactly how you envision it with multiple bespoke viewing modes:
- **Classic Shelf**: Realistic books lined on rich wood shelves, displaying dynamic book spines with custom foil lettering, realistic depth, and page thickness.
- **Polaroid Scrapbook**: Warm, nostalgic photographic polaroid prints capturing book covers with handwritten-style dates and reading status.
- **Carousel Showcase**: A cinematic, cover-forward presentation for browsing your favorite and current reads.
- **Minimalist Grid & List**: Clean, information-dense layouts for sorting large catalogs at a glance.

### 🕯️ Ambient e-Reader (ePub & PDF)
- **High-Fidelity ePub Engine**: Fully customizable reading surface with serif/sans typography controls, dynamic font scaling, margin paddings, and line height adjustments.
- **Integrated PDF Reader**: Smooth page flipping, progress scrubbers, page-accurate bookmarks, and direct jump navigation.
- **Flickering Candle Mode**: A delicate, animated candle flame overlay providing an ambient glow for late-night reading sessions.
- **Table of Contents Sync**: Instant chapter jumping and seamless reading position restoration across app restarts.

### 🎭 The Story Codex Engine
Unlock an in-depth, literary deconstruction of every book in your collection:
- **Figures of Destiny (Dramatis Personae)**: Dynamically surfaces key fictional characters—protagonists, love interests, antagonists—with their narrative archetypes and rich descriptions.
- **Premise & Synopsis**: Captures the beating heart of the story without spoilers.
- **Worldbuilding & Setting**: Explores the geography, historical era, and rules of the book’s universe.
- **Narrative Tropes & DNA**: Catalogs beloved tropes (e.g., *Enemies to Lovers*, *The Chosen One*, *Found Family*, *Morally Grey Protagonist*).
- **5D Flavor Profile**: Interactive sensory sliders visualizing the book's narrative spectrum (Dark vs. Light, Fast vs. Slow Pacing, Emotional Depth, Complexity, and Magic vs. Realism).

### 🎧 Seamless Audiobook Companion
- **Integrated Media Player**: Link audiobooks directly to their written counterparts.
- **Background Playback**: Background audio handler with notification shade controls, lock screen metadata, and playback speed toggles.
- **Vinyl Showcase**: A stylized, full-screen audio player complete with spinning vinyl aesthetics and chapter scrubbing.

### 📊 Reading Habits & Dual-View Analytics
- **Reading Calendar & Heatmap**: Visualize daily reading habits with a dual-view calendar and GitHub-style reading streak heatmap.
- **Reading Streaks & Flame Badges**: Celebrate uninterrupted reading streaks with dynamic streak badges.
- **Progress & Speed Tracking**: Track pages read, completion forecasts, reading goals, and annual milestones.

### ✍️ Quotes & Literary Journal
- Transcribe unforgettable quotes and passages.
- Tag and organize quotes by book, chapter, and sentiment for instant recollection.

### 🔍 Metadata Resolver & Goodreads Sync
- **Live Search**: Instant discovery with automatic cover resolution, synopsis, author bio, genre tagging, and page counts from Open Library & Google Books.
- **Goodreads & CSV Import**: Seamlessly import your entire reading history and shelves from Goodreads exports.

---

## 🎨 Dark Academia Aesthetic

Bookora is designed from the ground up to feel like walking into a candlelit Victorian library:
- **Warm Parchment (Light Mode)**: Soft, aged paper hues (`#F8F3E6`), warm terracotta accents, and vintage sepia borders.
- **Obsidian Slate (Dark Mode)**: Deep charcoal and slate tones (`#12161A`), antique brass highlights, and warm amber glows.
- **Bespoke Typography**: Elegant editorial serif typography paired with crisp, readable modern sans-serifs.

---

## 🛠️ Technology Stack

| Component | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Dart 3.x) |
| **State Architecture** | [Riverpod](https://riverpod.dev) |
| **Local Database** | [SQLite](https://pub.dev/packages/sqflite) (Persistent offline storage) |
| **Audio Handler** | `just_audio` & `audio_service` (Background media) |
| **Document Engines** | `epubx`, `webview_flutter`, `flutter_pdfview` |
| **Data Visualization** | `fl_chart`, `flutter_heatmap_calendar` |
| **Networking** | `dio`, `http`, `cached_network_image` |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `3.8.1` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extension
- An Android device or emulator (Android 5.0+ / API 21+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Khushi-Sanghvi/Bookora.git
   cd Bookora/between_world
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on a connected device:**
   ```bash
   flutter run
   ```

4. **Build release APK:**
   ```bash
   flutter build apk --split-per-abi
   ```
   The compiled APKs will be generated in `build/app/outputs/flutter-apk/`.

---

## 📦 Download Latest Release

Ready-to-install Android APKs are available directly on the [GitHub Releases](https://github.com/Khushi-Sanghvi/Bookora/releases/latest) page:

- **`app-arm64-v8a-release.apk`**: Recommended for almost all modern Android phones and tablets (64-bit).
- **`app-armeabi-v7a-release.apk`**: For older 32-bit Android devices.
- **`app-x86_64-release.apk`**: For Android emulators and ChromeOS tablets.

---

## 🤝 Contributing

Contributions, issues, and feature suggestions are always welcome!
Feel free to open an issue or submit a pull request:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/EnchantedFeature`)
3. Commit your Changes (`git commit -m 'feat: add an enchanted feature'`)
4. Push to the Branch (`git push origin feature/EnchantedFeature`)
5. Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">
  <sub>Crafted with passion for books and timeless literature.</sub>
</div>
