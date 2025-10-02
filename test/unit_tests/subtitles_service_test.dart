import "package:flutter_test/flutter_test.dart";
import "package:semo/services/subtitles_service.dart";

void main() {
  final SubtitlesService service = SubtitlesService();

  test("srtToVtt converts timestamps to VTT format", () {
    const String srt = "00:00:01,000 --> 00:00:02,000\nHello";

    final String vtt = service.srtToVtt(srt);

    expect(vtt.startsWith("WEBVTT"), isTrue);
    expect(vtt.contains("00:00:01.000 --> 00:00:02.000"), isTrue);
  });
}
