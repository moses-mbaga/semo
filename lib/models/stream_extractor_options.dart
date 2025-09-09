class StreamExtractorOptions {
  const StreamExtractorOptions({
    required this.tmdbId,
    this.season,
    this.episode,
    required this.title,
    this.movieReleaseYear,
    this.imdbId,
  }) : assert(
          (season == null && episode == null) || (season != null && episode != null),
          "If one of season or episode is provided, both must be provided.",
        );

  final int tmdbId;
  final int? season;
  final int? episode;
  final String title;
  final String? movieReleaseYear;
  final String? imdbId;
}
