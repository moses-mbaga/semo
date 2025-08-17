class Episode {
  Episode({
    required this.id,
    required this.number,
    required this.season,
    required this.name,
    required this.overview,
    required this.stillPath,
    required this.duration,
    this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json["id"] ?? 0,
    number: json["episode_number"] ?? 0,
    season: json["season_number"] ?? 0,
    name: json["name"] ?? "",
    overview: json["overview"] ?? "",
    stillPath: json["still_path"] ?? "",
    duration: json["runtime"] ?? 0,
    airDate: json["air_date"],
  );

  final int id;
  final int number;
  final int season;
  final String name;
  final String overview;
  final String stillPath;
  final int duration;
  final String? airDate;
}