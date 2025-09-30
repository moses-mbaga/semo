import "package:semo/models/genre.dart";

class Movie {
  Movie({
    required this.adult,
    required this.backdropPath,
    this.genreIds,
    this.genres,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
    required this.duration,
    this.trailerUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    adult: json["adult"] ?? false,
    backdropPath: json["backdrop_path"] ?? "",
    genreIds: json["genre_ids"] != null ? List<int>.from(json["genre_ids"]) : null,
    //ignore: always_specify_types
    genres: json["genres"] != null ? List<Genre>.from(json["genres"].map((json) => Genre.fromJson(json)).toList()) : null,
    id: json["id"] ?? 0,
    originalLanguage: json["original_language"] ?? "",
    originalTitle: json["original_title"] ?? "",
    overview: json["overview"] ?? "",
    popularity: double.parse((json["popularity"]?.toDouble() ?? 0.0).toStringAsFixed(1)),
    posterPath: json["poster_path"] ?? "",
    releaseDate: json["release_date"] ?? "",
    title: json["title"] ?? "",
    video: json["video"] ?? false,
    voteAverage: double.parse((json["vote_average"]?.toDouble() ?? 0.0).toStringAsFixed(1)),
    voteCount: json["vote_count"] ?? 0,
    duration: json["runtime"] ?? 0,
    trailerUrl: json["trailer_url"] ?? json["trailerUrl"],
  );

  final bool adult;
  final String backdropPath;
  final List<int>? genreIds;
  final List<Genre>? genres;
  final int id;
  final String originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String posterPath;
  final String releaseDate;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;
  final int duration;
  final String? trailerUrl;

  Movie copyWith({
    bool? adult,
    String? backdropPath,
    List<int>? genreIds,
    List<Genre>? genres,
    int? id,
    String? originalLanguage,
    String? originalTitle,
    String? overview,
    double? popularity,
    String? posterPath,
    String? releaseDate,
    String? title,
    bool? video,
    double? voteAverage,
    int? voteCount,
    int? duration,
    String? trailerUrl,
  }) => Movie(
        adult: adult ?? this.adult,
        backdropPath: backdropPath ?? this.backdropPath,
        genreIds: genreIds ?? this.genreIds,
        genres: genres ?? this.genres,
        id: id ?? this.id,
        originalLanguage: originalLanguage ?? this.originalLanguage,
        originalTitle: originalTitle ?? this.originalTitle,
        overview: overview ?? this.overview,
        popularity: popularity ?? this.popularity,
        posterPath: posterPath ?? this.posterPath,
        releaseDate: releaseDate ?? this.releaseDate,
        title: title ?? this.title,
        video: video ?? this.video,
        voteAverage: voteAverage ?? this.voteAverage,
        voteCount: voteCount ?? this.voteCount,
        duration: duration ?? this.duration,
        trailerUrl: trailerUrl ?? this.trailerUrl,
      );
}
