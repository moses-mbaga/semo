import "dart:convert";
import "dart:core";

import "package:dio/dio.dart";
import "package:semo/models/hls_manifest.dart";
import "package:semo/models/hls_audio_rendition.dart";
import "package:semo/models/hls_subtitle_rendition.dart";
import "package:semo/models/hls_variant_stream.dart";

class HlsParserService {
  const HlsParserService();

  Future<HlsManifest> fetchAndParseMasterPlaylist(String url, {Map<String, String>? headers}) async {
    final String body = await _httpGetText(url, headers: headers);
    return parseMasterPlaylist(body, baseUri: Uri.parse(url));
  }

  HlsManifest parseMasterPlaylist(String content, {Uri? baseUri}) {
    final List<String> lines = content.split(RegExp(r"\r?\n"));

    final List<HlsVariantStream> variants = <HlsVariantStream>[];
    final List<HlsAudioRendition> audios = <HlsAudioRendition>[];
    final List<HlsSubtitleRendition> subtitles = <HlsSubtitleRendition>[];

    if (lines.isEmpty || !lines.first.trim().startsWith("#EXTM3U")) {
      return HlsManifest(
        variants: variants,
        audios: audios,
        subtitles: subtitles,
      );
    }

    Map<String, String>? pendingStreamInf; // Attributes for the next URI line

    for (int i = 0; i < lines.length; i++) {
      final String rawLine = lines[i];
      final String line = rawLine.trim();

      if (line.isEmpty) {
        continue;
      }

      if (line.startsWith("#EXT-X-STREAM-INF")) {
        final int idx = line.indexOf(":");
        final String attrs = idx != -1 ? line.substring(idx + 1) : "";
        pendingStreamInf = _parseAttributeList(attrs);
        continue; // Next non-comment line should be the URI
      }

      if (line.startsWith("#EXT-X-MEDIA")) {
        final int idx = line.indexOf(":");
        final String attrs = idx != -1 ? line.substring(idx + 1) : "";
        final Map<String, String> map = _parseAttributeList(attrs);
        final String? type = map["TYPE"]?.toUpperCase();

        if (type == "AUDIO") {
          final String? groupId = _stripQuotes(map["GROUP-ID"]);
          final String? name = _stripQuotes(map["NAME"]);

          if (groupId != null && name != null) {
            final String? lang = _stripQuotes(map["LANGUAGE"]);
            final bool isDefault = _parseYesNo(map["DEFAULT"]) ?? false;
            final bool isAutoselect = _parseYesNo(map["AUTOSELECT"]) ?? false;
            final String? uriStr = _stripQuotes(map["URI"]);
            final Uri? uri = _maybeResolveUri(uriStr, baseUri);

            audios.add(
              HlsAudioRendition(
                name: name,
                language: lang,
                isDefault: isDefault,
                isAutoselect: isAutoselect,
                uri: uri,
              ),
            );
          }
        } else if (type == "SUBTITLES") {
          final String? groupId = _stripQuotes(map["GROUP-ID"]);
          final String? name = _stripQuotes(map["NAME"]);

          if (groupId != null && name != null) {
            final String? lang = _stripQuotes(map["LANGUAGE"]);
            final bool isDefault = _parseYesNo(map["DEFAULT"]) ?? false;
            final bool isAutoselect = _parseYesNo(map["AUTOSELECT"]) ?? false;
            final String? uriStr = _stripQuotes(map["URI"]);
            final Uri? uri = _maybeResolveUri(uriStr, baseUri);

            subtitles.add(
              HlsSubtitleRendition(
                name: name,
                language: lang,
                isDefault: isDefault,
                isAutoselect: isAutoselect,
                uri: uri,
              ),
            );
          }
        }

        continue;
      }

      // If we saw a STREAM-INF previously, the next non-tag, non-empty line is its URI
      if (pendingStreamInf != null && !line.startsWith("#")) {
        final Map<String, String> a = pendingStreamInf;
        pendingStreamInf = null;
        final String uriStr = line;
        final Uri? uri = _maybeResolveUri(uriStr, baseUri);

        if (uri == null) {
          continue;
        }

        final String? res = a["RESOLUTION"];
        int? width;
        int? height;

        if (res != null) {
          final List<String> parts = res.split("x");
          if (parts.length == 2) {
            width = int.tryParse(parts[0]);
            height = int.tryParse(parts[1]);
          }
        }

        final int? bandwidth = _parseInt(a["BANDWIDTH"]);
        final String? codecs = a["CODECS"] != null ? _stripQuotes(a["CODECS"]) : null;

        variants.add(
          HlsVariantStream(
            uri: uri,
            bandwidth: bandwidth,
            codecs: codecs,
            width: width,
            height: height,
          ),
        );

        continue;
      }
    }

    return HlsManifest(
      variants: variants,
      audios: audios,
      subtitles: subtitles,
    );
  }

  bool looksLikeMasterPlaylist(String content) {
    final String up = content.toUpperCase();
    return up.contains("#EXT-X-STREAM-INF") || up.contains("#EXT-X-MEDIA");
  }

  Future<String> _httpGetText(String url, {Map<String, String>? headers}) async {
    final Dio dio = Dio(
      BaseOptions(
        responseType: ResponseType.bytes,
        headers: headers,
        followRedirects: true,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        validateStatus: (int? status) => status != null && status >= 200 && status < 400,
      ),
    );

    final Response<List<int>> resp = await dio.get<List<int>>(url);
    final List<int> bytes = resp.data ?? <int>[];

    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  Uri? _maybeResolveUri(String? value, Uri? baseUri) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final Uri uri = Uri.parse(value);
    if (baseUri == null) {
      return uri;
    }

    return baseUri.resolveUri(uri);
  }

  int? _parseInt(String? s) {
    if (s == null) {
      return null;
    }

    return int.tryParse(s);
  }

  bool? _parseYesNo(String? s) {
    if (s == null) {
      return null;
    }

    final String v = s.replaceAll('"', "").toUpperCase();

    if (v == "YES") {
      return true;
    }
    if (v == "NO") {
      return false;
    }

    return null;
  }

  String? _stripQuotes(String? s) {
    if (s == null) {
      return null;
    }

    final String t = s.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      return t.substring(1, t.length - 1);
    }

    return t;
  }

  // Parse an HLS attribute list into key -> value (raw values, quoted preserved)
  // Handle commas inside quoted values
  Map<String, String> _parseAttributeList(String input) {
    final Map<String, String> out = <String, String>{};
    int i = 0;
    final int n = input.length;

    while (i < n) {
      // Skip separators/whitespace
      while (i < n && (input[i] == " " || input[i] == ",")) {
        i++;
      }

      if (i >= n) {
        break;
      }

      // Parse key
      final int keyStart = i;
      while (i < n && input[i] != "=" && input[i] != "," && input[i] != " ") {
        i++;
      }

      if (i >= n || input[i] != "=") {
        // Malformed; skip to next comma
        while (i < n && input[i] != ",") {
          i++;
        }
        continue;
      }

      final String key = input.substring(keyStart, i).trim();
      i++; // skip '='

      // Parse value
      String value;
      if (i < n && input[i] == '"') {
        i++; // skip opening quote
        final StringBuffer buf = StringBuffer();
        bool closed = false;

        while (i < n) {
          final String ch = input[i];

          if (ch == "\\" && i + 1 < n) {
            // Escaped character
            buf.write(input[i + 1]);
            i += 2;
            continue;
          }

          if (ch == '"') {
            closed = true;
            i++;
            break;
          }

          buf.write(ch);
          i++;
        }

        value = '"${buf.toString()}"';

        if (!closed) {
          // Unclosed quote; consume until comma
          while (i < n && input[i] != ",") {
            i++;
          }
        }
      } else {
        final int valStart = i;

        while (i < n && input[i] != ",") {
          i++;
        }

        value = input.substring(valStart, i).trim();
      }

      out[key.toUpperCase()] = value;
    }

    return out;
  }
}
