import "package:envied/envied.dart";

part "secrets_service.g.dart";

@Envied(path: ".env")
abstract class SecretsService {
  @EnviedField(varName: "TMDB_ACCESS_TOKEN", obfuscate: true)
  static String tmdbAccessToken = _SecretsService.tmdbAccessToken;

  @EnviedField(varName: "CINEPRO_BASE_URL", obfuscate: true)
  static String cineProBaseUrl = _SecretsService.cineProBaseUrl;
}
