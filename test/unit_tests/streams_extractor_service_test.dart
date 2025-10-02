import "package:flutter_test/flutter_test.dart";
import "package:semo/models/streaming_server.dart";
import "package:semo/services/streams_extractor_service/streams_extractor_service.dart";

void main() {
  test("Random server is present as the first streaming option", () {
    final List<StreamingServer> servers = StreamsExtractorService().getStreamingServers();

    expect(servers, isNotEmpty);
    expect(servers.first.name, "Random");
  });

  test("streaming server names are unique", () {
    final List<StreamingServer> servers = StreamsExtractorService().getStreamingServers();
    final Set<String> names = servers.map((StreamingServer s) => s.name).toSet();

    expect(names.length, servers.length);
  });
}
