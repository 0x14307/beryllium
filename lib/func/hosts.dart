import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class KnownHostEntry {
  KnownHostEntry({
    required this.pattern,
    required this.keyType,
    required this.fingerprint,
    this.hashed = false,
    this.revoked = false,
    this.salt,
    this.hostHash,
  });

  final String pattern;
  final String keyType;
  final String fingerprint;
  final bool hashed;
  final bool revoked;
  final Uint8List? salt;
  final Uint8List? hostHash;
}

class KnownHosts {
  KnownHosts(this.entries);
  final List<KnownHostEntry> entries;

  static Future<KnownHosts> load([String? path]) async {
    path ??= '${Platform.environment['HOME']}/.ssh/known_hosts';
    final file = File(path);
    if (!await file.exists()) return KnownHosts([]);
    return KnownHosts(_parse(await file.readAsString()));
  }

  static List<KnownHostEntry> _parse(String text) {
    final out = <KnownHostEntry>[];
    for (var raw in text.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      var revoked = false;
      if (line.startsWith('@revoked')) {
        revoked = true;
        line = line.substring(8).trim();
      } else if (line.startsWith('@cert-authority')) {
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) continue;

      final hostField = parts[0];
      final keyType = parts[1];
      final keyB64 = parts[2];

      final fingerprint = _fingerprint(keyB64);

      if (hostField.startsWith('|1|')) {
        final segs = hostField.split('|'); // ['', '1', salt, hash]
        if (segs.length < 4) continue;
        out.add(
          KnownHostEntry(
            pattern: hostField,
            keyType: keyType,
            fingerprint: fingerprint,
            hashed: true,
            revoked: revoked,
            salt: base64.decode(segs[2]),
            hostHash: base64.decode(segs[3]),
          ),
        );
      } else {
        for (final host in hostField.split(',')) {
          out.add(
            KnownHostEntry(
              pattern: host,
              keyType: keyType,
              fingerprint: fingerprint,
              revoked: revoked,
            ),
          );
        }
      }
    }
    return out;
  }

  static String _fingerprint(String keyB64) {
    final blob = base64.decode(keyB64);
    final b64 = base64.encode(sha256.convert(blob).bytes).replaceAll('=', '');
    return 'SHA256:$b64';
  }

  static bool _hostMatches(String pattern, String host, int port) {
    final wanted = port == 22 ? host : '[$host]:$port';
    if (pattern == wanted || pattern == host) return true;
    // '*.example.com'
    if (pattern.startsWith('*.') &&
        host.endsWith(pattern.substring(1)) &&
        host.split('.').length == pattern.split('.').length) {
      return true;
    }
    return false;
  }

  static bool _hashedMatches(KnownHostEntry e, String host, int port) {
    final name = port == 22 ? host : '[$host]:$port';
    final mac = Hmac(sha1, e.salt!).convert(utf8.encode(name)).bytes;
    if (mac.length != e.hostHash!.length) return false;
    var diff = 0;
    for (var i = 0; i < mac.length; i++) {
      diff |= mac[i] ^ e.hostHash![i];
    }
    return diff == 0;
  }

  bool verify(String host, int port, String type, String fingerprint) {
    final seen = fingerprint.replaceAll('=', '');
    final forHost =
        entries.where((e) {
          return e.hashed
              ? _hashedMatches(e, host, port)
              : _hostMatches(e.pattern, host, port);
        }).toList();

    if (forHost.any(
      (e) => e.revoked && e.fingerprint.replaceAll('=', '') == seen,
    )) {
      return false;
    }

    final sameType = forHost.where((e) => e.keyType == type).toList();
    if (sameType.isEmpty) return false;
    return sameType.any((e) => e.fingerprint.replaceAll('=', '') == seen);
  }
}
