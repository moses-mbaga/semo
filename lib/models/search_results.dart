import "package:index/models/movie.dart";
import "package:index/models/person.dart";
import "package:index/models/tv_show.dart";
import "package:index/enums/media_type.dart";

class SearchResults {
  SearchResults({
    this.page = 0,
    this.totalPages = 0,
    this.totalResults = 0,
    this.movies,
    this.tvShows,
    this.cast,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json, MediaType? mediaType) {
    List<Movie>? movies;
    List<TvShow>? tvShows;
    List<Person>? cast;

    if (mediaType != null) {
      List<Map<String, dynamic>> results = (json["results"] as List<dynamic>).cast<Map<String, dynamic>>();
      if (mediaType == MediaType.movies) {
        movies = results.map((Map<String, dynamic> json) => Movie.fromJson(json)).toList();
      } else {
        tvShows = results.map((Map<String, dynamic> json) => TvShow.fromJson(json)).toList();
      }
    } else {
      List<Map<String, dynamic>> results = (json["cast"] as List<dynamic>).cast<Map<String, dynamic>>();
      List<Person> allCast = results.map((Map<String, dynamic> json) => Person.fromJson(json)).toList();
      cast = allCast.where((Person person) => person.department == "Acting").toList();
    }

    return SearchResults(
      page: json["page"],
      totalPages: json["total_pages"],
      totalResults: json["total_results"],
      movies: movies,
      tvShows: tvShows,
      cast: cast,
    );
  }

  final int page;
  final int totalPages;
  final int totalResults;
  List<Movie>? movies;
  List<TvShow>? tvShows;
  List<Person>? cast;
}
