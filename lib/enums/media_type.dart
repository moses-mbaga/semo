enum MediaType {
  none,
  movies,
  tvShows,
  trailers;

  @override
  String toString() {
    switch (this) {
      case MediaType.none:
        return "None";
      case MediaType.movies:
        return "Movies";
      case MediaType.tvShows:
        return "TV Shows";
      case MediaType.trailers:
        return "Trailers";
    }
  }

  String toJsonField() {
    switch (this) {
      case MediaType.none:
        return "none";
      case MediaType.movies:
        return "movies";
      case MediaType.tvShows:
        return "tv_shows";
      case MediaType.trailers:
        return "trailers";
    }
  }
}
