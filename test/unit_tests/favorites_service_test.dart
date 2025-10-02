import "package:flutter_test/flutter_test.dart";
import "package:semo/services/favorites_service.dart";

void main() {
  final FavoritesService service = FavoritesService();

  group("getMovies", () {
    test("returns stored identifiers when present", () async {
      final Map<String, dynamic> favorites = <String, dynamic>{
        "movies": <int>[7, 9],
      };

      expect(await service.getMovies(favorites: favorites), <int>[7, 9]);
    });

    test("returns an empty list when the field is missing", () async {
      expect(await service.getMovies(favorites: <String, dynamic>{}), isEmpty);
    });
  });

  group("getTvShows", () {
    test("returns stored identifiers when present", () async {
      final Map<String, dynamic> favorites = <String, dynamic>{
        "tv_shows": <int>[3, 4],
      };

      expect(await service.getTvShows(favorites: favorites), <int>[3, 4]);
    });

    test("returns an empty list when the field is missing", () async {
      expect(await service.getTvShows(favorites: <String, dynamic>{}), isEmpty);
    });
  });
}
