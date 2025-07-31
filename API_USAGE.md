# استخدام واجهات برمجة التطبيقات في تطبيق INDEX

## واجهة برمجة تطبيقات TMDB

تستخدم واجهة برمجة تطبيقات TMDB للحصول على معلومات الأفلام والمسلسلات.

### مفتاح الوصول

```
eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI
```

### طلبات API الشائعة

#### الحصول على الأفلام الشائعة

```dart
Future<List<Movie>> getPopularMovies() async {
  final url = Uri.parse('https://api.themoviedb.org/3/movie/popular');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer ${Env.tmdbAccessToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((movie) => Movie.fromJson(movie)).toList();
  } else {
    throw Exception('Failed to load popular movies');
  }
}
```

#### البحث عن الأفلام

```dart
Future<List<Movie>> searchMovies(String query) async {
  final url = Uri.parse('https://api.themoviedb.org/3/search/movie?query=$query');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer ${Env.tmdbAccessToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((movie) => Movie.fromJson(movie)).toList();
  } else {
    throw Exception('Failed to search movies');
  }
}
```

#### الحصول على تفاصيل الفيلم

```dart
Future<Movie> getMovieDetails(int movieId) async {
  final url = Uri.parse('https://api.themoviedb.org/3/movie/$movieId?append_to_response=credits,videos');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer ${Env.tmdbAccessToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Movie.fromDetailJson(data);
  } else {
    throw Exception('Failed to load movie details');
  }
}
```

#### الحصول على المسلسلات الشائعة

```dart
Future<List<TvShow>> getPopularTvShows() async {
  final url = Uri.parse('https://api.themoviedb.org/3/tv/popular');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer ${Env.tmdbAccessToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((tvShow) => TvShow.fromJson(tvShow)).toList();
  } else {
    throw Exception('Failed to load popular TV shows');
  }
}
```

#### الحصول على تفاصيل المسلسل

```dart
Future<TvShow> getTvShowDetails(int tvShowId) async {
  final url = Uri.parse('https://api.themoviedb.org/3/tv/$tvShowId?append_to_response=credits,videos');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer ${Env.tmdbAccessToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return TvShow.fromDetailJson(data);
  } else {
    throw Exception('Failed to load TV show details');
  }
}
```

#### الحصول على تفاصيل الموسم

```dart
Future<Season> getSeasonDetails(int tvShowId, int seasonNumber) async {
  final url = Uri.parse('https://api.themoviedb.org/3/tv/$tvShowId/season/$seasonNumber');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer ${Env.tmdbAccessToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Season.fromJson(data);
  } else {
    throw Exception('Failed to load season details');
  }
}
```

## واجهة برمجة تطبيقات SUBDL

تستخدم واجهة برمجة تطبيقات SUBDL للحصول على الترجمات.

### مفتاح API

```
l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg
```

### طلبات API الشائعة

#### البحث عن الترجمات

```dart
Future<List<Subtitle>> searchSubtitles(String imdbId, String language) async {
  final url = Uri.parse('https://api.subdl.com/search?imdb_id=$imdbId&language=$language');
  final response = await http.get(
    url,
    headers: {
      'X-API-Key': Env.subdlApiKey,
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((subtitle) => Subtitle.fromJson(subtitle)).toList();
  } else {
    throw Exception('Failed to search subtitles');
  }
}
```

#### تنزيل الترجمة

```dart
Future<String> downloadSubtitle(String fileId) async {
  final url = Uri.parse('https://api.subdl.com/download/$fileId');
  final response = await http.get(
    url,
    headers: {
      'X-API-Key': Env.subdlApiKey,
    },
  );

  if (response.statusCode == 200) {
    // حفظ ملف الترجمة
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/subtitles/$fileId.srt');
    await file.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  } else {
    throw Exception('Failed to download subtitle');
  }
}
```

## استخدام واجهات برمجة التطبيقات في التطبيق

### إنشاء خدمة TMDB

أنشئ ملف `lib/services/tmdb_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:index/models/movie.dart';
import 'package:index/models/tv_show.dart';
import 'package:index/models/season.dart';
import 'package:index/utils/env/env.dart';

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer ${Env.tmdbAccessToken}',
    'Content-Type': 'application/json',
  };

  // الأفلام
  static Future<List<Movie>> getPopularMovies() async {
    final url = Uri.parse('$_baseUrl/movie/popular');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  static Future<List<Movie>> getTrendingMovies() async {
    final url = Uri.parse('$_baseUrl/trending/movie/week');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load trending movies');
    }
  }

  static Future<Movie> getMovieDetails(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId?append_to_response=credits,videos');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Movie.fromDetailJson(data);
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  static Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.parse('$_baseUrl/search/movie?query=$query');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }

  // المسلسلات
  static Future<List<TvShow>> getPopularTvShows() async {
    final url = Uri.parse('$_baseUrl/tv/popular');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((tvShow) => TvShow.fromJson(tvShow)).toList();
    } else {
      throw Exception('Failed to load popular TV shows');
    }
  }

  static Future<List<TvShow>> getTrendingTvShows() async {
    final url = Uri.parse('$_baseUrl/trending/tv/week');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((tvShow) => TvShow.fromJson(tvShow)).toList();
    } else {
      throw Exception('Failed to load trending TV shows');
    }
  }

  static Future<TvShow> getTvShowDetails(int tvShowId) async {
    final url = Uri.parse('$_baseUrl/tv/$tvShowId?append_to_response=credits,videos');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return TvShow.fromDetailJson(data);
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

  static Future<Season> getSeasonDetails(int tvShowId, int seasonNumber) async {
    final url = Uri.parse('$_baseUrl/tv/$tvShowId/season/$seasonNumber');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Season.fromJson(data);
    } else {
      throw Exception('Failed to load season details');
    }
  }

  static Future<List<TvShow>> searchTvShows(String query) async {
    final url = Uri.parse('$_baseUrl/search/tv?query=$query');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((tvShow) => TvShow.fromJson(tvShow)).toList();
    } else {
      throw Exception('Failed to search TV shows');
    }
  }
}
```

### إنشاء خدمة SUBDL

أنشئ ملف `lib/services/subtitle_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:index/models/subtitle.dart';
import 'package:index/utils/env/env.dart';

class SubtitleService {
  static const String _baseUrl = 'https://api.subdl.com';

  static Map<String, String> get _headers => {
    'X-API-Key': Env.subdlApiKey,
    'Content-Type': 'application/json',
  };

  static Future<List<Subtitle>> searchSubtitles(String imdbId, String language) async {
    final url = Uri.parse('$_baseUrl/search?imdb_id=$imdbId&language=$language');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((subtitle) => Subtitle.fromJson(subtitle)).toList();
    } else {
      throw Exception('Failed to search subtitles');
    }
  }

  static Future<String> downloadSubtitle(String fileId) async {
    final url = Uri.parse('$_baseUrl/download/$fileId');
    final response = await http.get(
      url,
      headers: {
        'X-API-Key': Env.subdlApiKey,
      },
    );

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/subtitles/$fileId.srt');
      await file.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download subtitle');
    }
  }
}
```

### استخدام الخدمات في التطبيق

استخدم الخدمات في شاشات التطبيق:

```dart
import 'package:index/services/tmdb_service.dart';
import 'package:index/services/subtitle_service.dart';

// ...

// الحصول على الأفلام الشائعة
final movies = await TmdbService.getPopularMovies();

// البحث عن الأفلام
final searchResults = await TmdbService.searchMovies(query);

// الحصول على تفاصيل الفيلم
final movieDetails = await TmdbService.getMovieDetails(movieId);

// البحث عن الترجمات
final subtitles = await SubtitleService.searchSubtitles(imdbId, 'ar');

// تنزيل الترجمة
final subtitlePath = await SubtitleService.downloadSubtitle(fileId);
```