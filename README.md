# Semo

![Semo Screenshots](https://raw.githubusercontent.com/moses-mbaga/semo/refs/heads/main/banner.png)

Semo is designed to offer a seamless movie and TV show streaming experience. With support for multiple streaming servers, synced watch progress, YouTube trailer playback, and fully customizable subtitles, Semo aims to be your go-to streaming app for enjoying your favorite content.

## Features

🗂 Comprehensive Library

- Access almost all movies and TV shows.
- Explore a vast library to find something for everyone using TMDB data.

🎥 Stream Playback

- Play movies and TV shows directly using high-quality HLS or file streams.
- Multiple streaming servers with automatic fallbacks and quality labelling for direct-file sources.

⏳ Synced Watch Progress

- Automatically syncs playback progress for movies and episodes.
- Never lose your spot, even if you switch devices or revisit content later.

🔠 Customizable Subtitles

- Support for .srt subtitle files (converted on the fly to WebVTT for playback).
- Filter subtitles by language and cache downloads for offline reuse.

▶️ Trailers & Extras

- Play official trailers via resilient multi-backend YouTube extraction.
- Sniff additional media links directly from provider pages when needed.

## Download ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/moses-mbaga/semo/total?link=https%3A%2F%2Fgithub.com%2Fmoses-mbaga%2Fsemo%2Freleases)

Download APK
[![Download APK](https://custom-icon-badges.demolab.com/badge/-Download-F25278?style=for-the-badge&logo=download&logoColor=white&color=AB261D)](https://github.com/moses-mbaga/semo/releases)

Download IPA
[![Download IPA](https://custom-icon-badges.demolab.com/badge/-Download-F25278?style=for-the-badge&logo=download&logoColor=white&color=AB261D)](https://github.com/moses-mbaga/semo/releases)

## Tech Stack

**Client:** Flutter

**Server:** Firebase

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- API services:
  - [TMDB Service](docs/api/TMDB.md)
  - [Stream Extractor Service](docs/api/STREAMS_EXTRACTOR.md)
  - [YouTube Extractor Service](docs/api/YOUTUBE_EXTRACTOR.md)
  - [Page Network Requests Service](docs/api/PAGE_NETWORK_REQUESTS.md)
  - [Video Quality Service](docs/api/VIDEO_QUALITY.md)
  - [Subtitle Service](docs/api/SUBTITLES.md)
  - [ZIP to VTT Service](docs/api/ZIP_TO_VTT.md)
  - [App Preferences Service](docs/api/APP_PREFERENCES.md)
  - [Auth Service](docs/api/AUTH.md)
  - [Favorites Service](docs/api/FAVORITES.md)
  - [Recently Watched Service](docs/api/RECENTLY_WATCHED.md)
  - [Recent Searches Service](docs/api/RECENT_SEARCHES.md)
  - [Secrets Service](docs/api/SECRETS.md)
- [TODOs](docs/TODO.md)

## Installation

Prerequisites:
- [Flutter SDK](https://flutter.dev/) (latest stable version).
- A code editor (e.g., [Android Studio](https://developer.android.com/studio), [VSCode](https://code.visualstudio.com/)).
- A Firebase account

Instructions:

- Clone the repository
```bash
git clone https://github.com/moses-mbaga/semo.git
cd semo
```

- Install the dependencies:
```bash
flutter pub get
```

- Under the parent directory, create a ```.env``` file, which will contain the secrets required to run the app. An example can be found in ```.env.example```.

- Auto generate asset and env helpers using build_runner:
```bash
dart run build_runner build --delete-conflicting-outputs
```

- Add Firebase to the app using FlutterFire CLI. You can follow instructions from the [official documentation](https://firebase.google.com/docs/flutter/setup)

- Run the app:
```bash
flutter run
```

## Support

If you encounter any issues or have suggestions, please open an issue in the [GitHub Issues](https://github.com/moses-mbaga/semo/issues) section.

Enjoy streaming with Semo! 🌟
