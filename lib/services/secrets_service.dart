import "package:envied/envied.dart";

part "secrets_service.g.dart";

@Envied(path: ".env")
abstract class SecretsService {
  @EnviedField(varName: "TMDB_ACCESS_TOKEN", obfuscate: true)
  static String tmdbAccessToken = _SecretsService.tmdbAccessToken;

  @EnviedField(varName: "SUBDL_API_KEY", obfuscate: true)
  static String subdlApiKey = _SecretsService.subdlApiKey;

  @EnviedField(varName: "CLOUDFLARE_WORKER_PROXY", obfuscate: true)
  static String cloudflareWorkerProxy = _SecretsService.cloudflareWorkerProxy;
}
