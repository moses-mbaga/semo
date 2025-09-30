import "package:semo/models/genre.dart";

class TvShow {
  TvShow({
    required this.adult,
    required this.backdropPath,
    this.genreIds,
    this.genres,
    required this.id,
    required this.originalLanguage,
    required this.originalName,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.firstAirDate,
    required this.name,
    required this.voteAverage,
    required this.voteCount,
    this.trailerUrl,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) => TvShow(
      adult: json["adult"] ?? false,
      backdropPath: json["backdrop_path"] ?? "",
      genreIds: json["genre_ids"] != null ? List<int>.from(json["genre_ids"]) : null,
      //ignore: always_specify_types
      genres: json["genres"] != null ? List<Genre>.from(json["genres"].map((json) => Genre.fromJson(json)).toList()) : null,
      id: json["id"] ?? 0,
      originalLanguage: json["original_language"] ?? "",
      originalName: json["original_name"] ?? "",
      overview: json["overview"] ?? "",
      popularity: double.parse((json["popularity"]?.toDouble() ?? 0.0).toStringAsFixed(1)),
      posterPath: json["poster_path"] ?? "",
      firstAirDate: json["first_air_date"] ?? "",
      name: json["name"] ?? "",
      voteAverage: double.parse((json["vote_average"]?.toDouble() ?? 0.0).toStringAsFixed(1)),
      voteCount: json["vote_count"] ?? 0,
      trailerUrl: json["trailer_url"] ?? json["trailerUrl"],
    );

  final bool adult;
  final String backdropPath;
  final List<int>? genreIds;
  final List<Genre>? genres;
  final int id;
  final String originalLanguage;
  final String originalName;
  final String overview;
  final double popularity;
  final String posterPath;
  final String firstAirDate;
  final String name;
  final double voteAverage;
  final int voteCount;
  final String? trailerUrl;

  TvShow copyWith({
    bool? adult,
    String? backdropPath,
    List<int>? genreIds,
    List<Genre>? genres,
    int? id,
    String? originalLanguage,
    String? originalName,
    String? overview,
    double? popularity,
    String? posterPath,
    String? firstAirDate,
    String? name,
    double? voteAverage,
    int? voteCount,
    String? trailerUrl,
  }) => TvShow(
        adult: adult ?? this.adult,
        backdropPath: backdropPath ?? this.backdropPath,
        genreIds: genreIds ?? this.genreIds,
        genres: genres ?? this.genres,
        id: id ?? this.id,
        originalLanguage: originalLanguage ?? this.originalLanguage,
        originalName: originalName ?? this.originalName,
        overview: overview ?? this.overview,
        popularity: popularity ?? this.popularity,
        posterPath: posterPath ?? this.posterPath,
        firstAirDate: firstAirDate ?? this.firstAirDate,
        name: name ?? this.name,
        voteAverage: voteAverage ?? this.voteAverage,
        voteCount: voteCount ?? this.voteCount,
        trailerUrl: trailerUrl ?? this.trailerUrl,
      );
}
