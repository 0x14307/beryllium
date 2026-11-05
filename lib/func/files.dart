import 'package:dartssh2/dartssh2.dart';

class RemoteFileEntry {
  const RemoteFileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
  });

  final String name;
  final String path;
  final bool isDirectory;
}

class SftpFileBrowser {
  SSHClient? _client;
  SftpClient? _sftp;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    close();

    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: () => password,
    );

    try {
      final sftp = await client.sftp();
      _client = client;
      _sftp = sftp;
    } catch (_) {
      client.close();
      rethrow;
    }
  }

  Future<String> getHomeDirectory() async {
    final sftp = _requireSftp();
    return sftp.absolute('.');
  }

  Future<List<RemoteFileEntry>> listDirectory(String path) async {
    final entries = await _requireSftp().listdir(path);
    final files =
        entries
            .where((entry) => entry.filename != '.' && entry.filename != '..')
            .map((entry) {
              final isDirectory =
                  entry.attr.mode?.type == SftpFileType.directory;
              return RemoteFileEntry(
                name: entry.filename,
                path: _joinPath(path, entry.filename),
                isDirectory: isDirectory,
              );
            })
            .toList()
          ..sort((a, b) {
            if (a.isDirectory != b.isDirectory) {
              return a.isDirectory ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    return files;
  }

  void close() {
    _sftp = null;
    _client?.close();
    _client = null;
  }

  SftpClient _requireSftp() {
    final sftp = _sftp;
    if (sftp == null) {
      throw StateError('The SFTP browser is not connected.');
    }
    return sftp;
  }

  String _joinPath(String directory, String name) {
    if (directory == '/') return '/$name';
    return '${directory.replaceFirst(RegExp(r'/+$'), '')}/$name';
  }
}
