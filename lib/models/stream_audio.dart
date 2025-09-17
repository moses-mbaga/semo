class StreamAudio {
  const StreamAudio({
    required this.language,
    required this.url,
    required this.isDefault,
  });

  final String language;
  final String url;
  final bool isDefault;
}
