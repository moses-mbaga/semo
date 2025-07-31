# هيكل قاعدة البيانات المحلية في تطبيق INDEX

## نظرة عامة

يستخدم تطبيق INDEX قاعدة بيانات محلية لتخزين بيانات المستخدم والتفضيلات والمحتوى المفضل. يتم استخدام SharedPreferences لتخزين البيانات البسيطة، ويمكن استخدام SQLite لتخزين البيانات الأكثر تعقيدًا.

## SharedPreferences

### بيانات المستخدم

```dart
// تخزين بيانات المستخدم
await prefs.setString('user_id', userId);
await prefs.setString('user_name', userName);
await prefs.setString('user_email', userEmail);
await prefs.setString('user_avatar', userAvatar);
await prefs.setBool('is_guest', isGuest);
await prefs.setString('auth_token', authToken);
await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);

// استرجاع بيانات المستخدم
final userId = prefs.getString('user_id') ?? '';
final userName = prefs.getString('user_name') ?? '';
final userEmail = prefs.getString('user_email') ?? '';
final userAvatar = prefs.getString('user_avatar') ?? '';
final isGuest = prefs.getBool('is_guest') ?? true;
final authToken = prefs.getString('auth_token') ?? '';
final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
```

### تفضيلات التطبيق

```dart
// تخزين تفضيلات التطبيق
await prefs.setBool('dark_mode', isDarkMode);
await prefs.setString('language', language);
await prefs.setBool('notifications_enabled', notificationsEnabled);
await prefs.setBool('auto_play', autoPlay);
await prefs.setInt('video_quality', videoQuality);

// استرجاع تفضيلات التطبيق
final isDarkMode = prefs.getBool('dark_mode') ?? false;
final language = prefs.getString('language') ?? 'ar';
final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
final autoPlay = prefs.getBool('auto_play') ?? true;
final videoQuality = prefs.getInt('video_quality') ?? 720;
```

### تفضيلات الترجمة

```dart
// تخزين تفضيلات الترجمة
await prefs.setBool('subtitles_enabled', subtitlesEnabled);
await prefs.setString('subtitle_language', subtitleLanguage);
await prefs.setDouble('subtitle_size', subtitleSize);
await prefs.setString('subtitle_color', subtitleColor);
await prefs.setString('subtitle_background', subtitleBackground);
await prefs.setDouble('subtitle_opacity', subtitleOpacity);

// استرجاع تفضيلات الترجمة
final subtitlesEnabled = prefs.getBool('subtitles_enabled') ?? true;
final subtitleLanguage = prefs.getString('subtitle_language') ?? 'ar';
final subtitleSize = prefs.getDouble('subtitle_size') ?? 16.0;
final subtitleColor = prefs.getString('subtitle_color') ?? 'FFFFFF';
final subtitleBackground = prefs.getString('subtitle_background') ?? '000000';
final subtitleOpacity = prefs.getDouble('subtitle_opacity') ?? 0.8;
```

### تقدم المشاهدة

```dart
// تخزين تقدم مشاهدة الفيلم
final movieProgressKey = 'movie_progress_$movieId';
await prefs.setInt(movieProgressKey, progressInSeconds);

// استرجاع تقدم مشاهدة الفيلم
final movieProgressKey = 'movie_progress_$movieId';
final progressInSeconds = prefs.getInt(movieProgressKey) ?? 0;

// تخزين تقدم مشاهدة الحلقة
final episodeProgressKey = 'episode_progress_${tvShowId}_${seasonNumber}_${episodeNumber}';
await prefs.setInt(episodeProgressKey, progressInSeconds);

// استرجاع تقدم مشاهدة الحلقة
final episodeProgressKey = 'episode_progress_${tvShowId}_${seasonNumber}_${episodeNumber}';
final progressInSeconds = prefs.getInt(episodeProgressKey) ?? 0;
```

### المفضلة

```dart
// تخزين الأفلام المفضلة
final favoriteMoviesJson = jsonEncode(favoriteMovies.map((m) => m.toJson()).toList());
await prefs.setString('favorite_movies', favoriteMoviesJson);

// استرجاع الأفلام المفضلة
final favoriteMoviesJson = prefs.getString('favorite_movies') ?? '[]';
final favoriteMoviesList = jsonDecode(favoriteMoviesJson) as List;
final favoriteMovies = favoriteMoviesList.map((json) => Movie.fromJson(json)).toList();

// تخزين المسلسلات المفضلة
final favoriteTvShowsJson = jsonEncode(favoriteTvShows.map((t) => t.toJson()).toList());
await prefs.setString('favorite_tv_shows', favoriteTvShowsJson);

// استرجاع المسلسلات المفضلة
final favoriteTvShowsJson = prefs.getString('favorite_tv_shows') ?? '[]';
final favoriteTvShowsList = jsonDecode(favoriteTvShowsJson) as List;
final favoriteTvShows = favoriteTvShowsList.map((json) => TvShow.fromJson(json)).toList();
```

### سجل البحث

```dart
// تخزين سجل البحث
final searchHistoryJson = jsonEncode(searchHistory);
await prefs.setString('search_history', searchHistoryJson);

// استرجاع سجل البحث
final searchHistoryJson = prefs.getString('search_history') ?? '[]';
final searchHistory = (jsonDecode(searchHistoryJson) as List).cast<String>();
```

## SQLite (اختياري)

يمكن استخدام SQLite لتخزين البيانات الأكثر تعقيدًا. فيما يلي مثال على كيفية إنشاء قاعدة بيانات SQLite:

### إنشاء قاعدة البيانات

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  static Database? _database;
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'index.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // جدول المستخدمين
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        avatar TEXT,
        is_guest INTEGER,
        auth_token TEXT,
        login_timestamp INTEGER
      )
    ''');
    
    // جدول الأفلام المفضلة
    await db.execute('''
      CREATE TABLE favorite_movies (
        id INTEGER PRIMARY KEY,
        title TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        overview TEXT,
        release_date TEXT,
        vote_average REAL,
        added_at INTEGER
      )
    ''');
    
    // جدول المسلسلات المفضلة
    await db.execute('''
      CREATE TABLE favorite_tv_shows (
        id INTEGER PRIMARY KEY,
        name TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        overview TEXT,
        first_air_date TEXT,
        vote_average REAL,
        added_at INTEGER
      )
    ''');
    
    // جدول تقدم المشاهدة
    await db.execute('''
      CREATE TABLE watch_progress (
        id TEXT PRIMARY KEY,
        media_type TEXT,
        media_id INTEGER,
        season_number INTEGER,
        episode_number INTEGER,
        progress_seconds INTEGER,
        duration_seconds INTEGER,
        last_watched_at INTEGER
      )
    ''');
    
    // جدول سجل البحث
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT,
        searched_at INTEGER
      )
    ''');
  }
}
```

### استخدام قاعدة البيانات

#### إضافة فيلم إلى المفضلة

```dart
Future<void> addFavoriteMovie(Movie movie) async {
  final db = await DatabaseHelper.instance.database;
  await db.insert(
    'favorite_movies',
    {
      'id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'backdrop_path': movie.backdropPath,
      'overview': movie.overview,
      'release_date': movie.releaseDate,
      'vote_average': movie.voteAverage,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

#### الحصول على الأفلام المفضلة

```dart
Future<List<Movie>> getFavoriteMovies() async {
  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('favorite_movies', orderBy: 'added_at DESC');
  
  return List.generate(maps.length, (i) {
    return Movie(
      id: maps[i]['id'] as int,
      title: maps[i]['title'] as String,
      posterPath: maps[i]['poster_path'] as String?,
      backdropPath: maps[i]['backdrop_path'] as String?,
      overview: maps[i]['overview'] as String,
      releaseDate: maps[i]['release_date'] as String?,
      voteAverage: maps[i]['vote_average'] as double,
    );
  });
}
```

#### حفظ تقدم المشاهدة

```dart
Future<void> saveWatchProgress({
  required String mediaType,
  required int mediaId,
  int? seasonNumber,
  int? episodeNumber,
  required int progressSeconds,
  required int durationSeconds,
}) async {
  final db = await DatabaseHelper.instance.database;
  
  final id = mediaType == 'movie'
      ? 'movie_$mediaId'
      : 'tv_${mediaId}_${seasonNumber}_$episodeNumber';
  
  await db.insert(
    'watch_progress',
    {
      'id': id,
      'media_type': mediaType,
      'media_id': mediaId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'progress_seconds': progressSeconds,
      'duration_seconds': durationSeconds,
      'last_watched_at': DateTime.now().millisecondsSinceEpoch,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

#### الحصول على تقدم المشاهدة

```dart
Future<Map<String, dynamic>?> getWatchProgress({
  required String mediaType,
  required int mediaId,
  int? seasonNumber,
  int? episodeNumber,
}) async {
  final db = await DatabaseHelper.instance.database;
  
  final id = mediaType == 'movie'
      ? 'movie_$mediaId'
      : 'tv_${mediaId}_${seasonNumber}_$episodeNumber';
  
  final maps = await db.query(
    'watch_progress',
    where: 'id = ?',
    whereArgs: [id],
  );
  
  if (maps.isNotEmpty) {
    return maps.first;
  }
  
  return null;
}
```

## مزامنة البيانات (اختياري)

إذا كنت ترغب في إضافة ميزة مزامنة البيانات بين الأجهزة، يمكنك استخدام خدمة سحابية مثل Firebase Firestore أو خدمة مخصصة. فيما يلي مثال على كيفية مزامنة البيانات:

```dart
Future<void> syncUserData() async {
  // الحصول على البيانات المحلية
  final localData = await getLocalUserData();
  
  // الحصول على البيانات السحابية
  final cloudData = await getCloudUserData();
  
  // مقارنة البيانات وتحديثها
  if (localData.lastUpdated > cloudData.lastUpdated) {
    // تحديث البيانات السحابية
    await updateCloudUserData(localData);
  } else {
    // تحديث البيانات المحلية
    await updateLocalUserData(cloudData);
  }
}
```