import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../func/files.dart';
import 'device.dart';

class FileTree extends StatefulWidget {
  const FileTree({super.key, required this.device});

  final RemoteDevice? device;

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  SftpFileBrowser? _browser;
  List<RemoteFileEntry> _entries = [];
  String? _currentPath;
  Object? _error;
  int _operation = 0;
  bool _isLoading = false;
  late String _localPath = _initialLocalPath;
  List<RemoteFileEntry> _localEntries = [];
  Object? _localError;
  int _localOperation = 0;
  bool _isLocalLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_openLocalDirectory(_localPath));
    if (widget.device != null) unawaited(_connect());
  }

  @override
  void didUpdateWidget(covariant FileTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) {
      unawaited(_connect());
    }
  }

  Future<void> _connect() async {
    final operation = ++_operation;
    _browser?.close();
    _browser = null;
    _currentPath = null;
    _entries = [];
    _error = null;

    final device = widget.device;
    if (device == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final browser = SftpFileBrowser();
    try {
      await browser.connect(
        host: device.host,
        port: device.port,
        username: device.username,
        password: device.password,
      );
      final path = await browser.getHomeDirectory();
      final entries = await browser.listDirectory(path);

      if (!mounted || operation != _operation) {
        browser.close();
        return;
      }

      _browser = browser;
      setState(() {
        _currentPath = path;
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      browser.close();
      if (!mounted || operation != _operation) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openDirectory(String path) async {
    final browser = _browser;
    if (browser == null) {
      await _connect();
      return;
    }

    final operation = ++_operation;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await browser.listDirectory(path);
      if (!mounted || operation != _operation) return;
      setState(() {
        _currentPath = path;
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || operation != _operation) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocalDirectory(String path) async {
    final operation = ++_localOperation;
    setState(() {
      _localPath = path;
      _isLocalLoading = true;
      _localError = null;
    });

    try {
      final entries =
          await Directory(path).list(followLinks: false).asyncMap((entity) {
            return RemoteFileEntry(
              name: _basename(entity.path),
              path: entity.path,
              isDirectory: entity is Directory,
            );
          }).toList();
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (!mounted || operation != _localOperation) return;
      setState(() {
        _localEntries = entries;
        _isLocalLoading = false;
      });
    } catch (error) {
      if (!mounted || operation != _localOperation) return;
      setState(() {
        _localError = error;
        _isLocalLoading = false;
      });
    }
  }

  String get _initialLocalPath {
    final homeDirectory =
        Platform.isWindows
            ? Platform.environment['USERPROFILE']
            : Platform.environment['HOME'];
    return homeDirectory ?? Directory.current.path;
  }

  String _basename(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((part) => part.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  String? get _parentPath {
    final path = _currentPath;
    if (path == null || path == '/') return null;
    final separator = path.lastIndexOf('/');
    if (separator <= 0) return '/';
    return path.substring(0, separator);
  }

  String? get _localParentPath {
    final parent = Directory(_localPath).parent.path;
    return parent == _localPath ? null : parent;
  }

  @override
  void dispose() {
    _operation++;
    _localOperation++;
    _browser?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    return Row(
      children: [
        Expanded(child: _buildLocalPane()),
        const VerticalDivider(width: 1),
        Expanded(child: _buildRemotePane(device)),
      ],
    );
  }

  Widget _buildLocalPane() {
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            tooltip: 'Parent directory',
            onPressed:
                _localParentPath == null
                    ? null
                    : () => _openLocalDirectory(_localParentPath!),
            icon: const Icon(Icons.arrow_upward),
          ),
          title: const Text('Local files'),
          subtitle: Text(
            _localPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Refresh local files',
            onPressed:
                _isLocalLoading ? null : () => _openLocalDirectory(_localPath),
            icon: const Icon(Icons.refresh),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildLocalContents()),
      ],
    );
  }

  Widget _buildRemotePane(RemoteDevice? device) {
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            tooltip: 'Parent directory',
            onPressed:
                _parentPath == null ? null : () => _openDirectory(_parentPath!),
            icon: const Icon(Icons.arrow_upward),
          ),
          title: Text(device?.host ?? 'Remote files'),
          subtitle: Text(
            device == null
                ? 'Select a device to connect.'
                : (_currentPath ?? 'Connecting...'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Refresh remote files',
            onPressed:
                device == null || _isLoading
                    ? null
                    : () {
                      final path = _currentPath;
                      if (path == null) {
                        unawaited(_connect());
                      } else {
                        unawaited(_openDirectory(path));
                      }
                    },
            icon: const Icon(Icons.refresh),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              device == null
                  ? const Center(
                    child: Text('Select a device to browse remote files.'),
                  )
                  : _buildContents(),
        ),
      ],
    );
  }

  Widget _buildLocalContents() {
    if (_isLocalLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load local directory: $_localError'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _openLocalDirectory(_localPath),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_localEntries.isEmpty) {
      return const Center(child: Text('This directory is empty.'));
    }

    return ListView.builder(
      itemCount: _localEntries.length,
      itemBuilder: (context, index) {
        final entry = _localEntries[index];
        return ListTile(
          leading: Icon(
            entry.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file,
          ),
          title: Text(entry.name),
          onTap:
              entry.isDirectory ? () => _openLocalDirectory(entry.path) : null,
        );
      },
    );
  }

  Widget _buildContents() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load directory: $_error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final path = _currentPath;
                  if (path == null) {
                    unawaited(_connect());
                  } else {
                    unawaited(_openDirectory(path));
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('This directory is empty.'));
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return ListTile(
          leading: Icon(
            entry.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file,
          ),
          title: Text(entry.name),
          onTap: entry.isDirectory ? () => _openDirectory(entry.path) : null,
        );
      },
    );
  }
}
