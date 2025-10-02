import "package:flutter_test/flutter_test.dart";
import "package:semo/services/recently_watched_service.dart";

Map<String, dynamic> _buildFixture() => <String, dynamic>{
      "movies": <String, Map<String, dynamic>>{
        "10": <String, dynamic>{"progress": 15, "timestamp": 1000},
        "20": <String, dynamic>{"progress": 70, "timestamp": 2000},
      },
      "tv_shows": <String, dynamic>{
        "1": <String, dynamic>{
          "visibleInMenu": true,
          "101": <String, dynamic>{
            "1": <String, dynamic>{"progress": 50, "timestamp": 1500},
          },
        },
      },
    };

void main() {
  final RecentlyWatchedService service = RecentlyWatchedService();

  test("getMovieProgress returns the stored progress", () {
    final Map<String, dynamic> data = _buildFixture();

    expect(service.getMovieProgress(20, data), 70);
  });

  test("getMovieProgress returns 0 for missing entries", () {
    final Map<String, dynamic> data = _buildFixture();

    expect(service.getMovieProgress(99, data), 0);
  });

  test("getEpisodesFromCache strips metadata and returns episodes", () {
    final Map<String, dynamic> data = _buildFixture();

    final Map<String, Map<String, dynamic>> result = service.getEpisodesFromCache(1, 101, data);

    expect(result.keys, contains("1"));
    expect(result["1"]?["progress"], 50);
    expect(result.containsKey("visibleInMenu"), isFalse);
  });

  test("getEpisodeProgress returns the stored episode progress", () {
    final Map<String, dynamic> data = _buildFixture();

    expect(service.getEpisodeProgress(1, 101, 1, data), 50);
  });
}
