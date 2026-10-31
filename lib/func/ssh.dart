import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import 'hosts.dart';

class SSH {
  void openConnection(
    String host,
    int port,
    String user,
    String password,
  ) async {
    final known = await KnownHosts.load();
    final client = SSHClient(
      await SSHSocket.connect(host, port),
      username: user,
      identities: [
        ...SSHKeyPair.fromPem(
          await File(
            '${Platform.environment['HOME']}/.ssh/id_ed25519',
          ).readAsString(),
        ),
      ],
      onPasswordRequest: () => password,
      onVerifyHostKey: (type, fingerprint) {
        final print = utf8.decode(fingerprint);
        final isClientTrusted = known.verify(host, port, type, print);
        if (!isClientTrusted) {
          stderr.writeln("ERROR! KEY MISMATCH $host");
        }
        return true;
      },
    );
  }
}
