class MediaProgress {
  const MediaProgress({
    this.progress = Duration.zero,
    this.total = Duration.zero,
    this.buffered = Duration.zero,
    this.isBuffering = true,
  });

  final Duration progress;
  final Duration total;
  final Duration buffered;
  final bool isBuffering;
}
