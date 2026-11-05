import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import 'device.dart';

class CreateTerm extends StatelessWidget {
  const CreateTerm({super.key, required this.device});

  final RemoteDevice? device;

  @override
  Widget build(BuildContext context) {
    final device = this.device;
    if (device == null) {
      return const Center(child: Text('Select a device to connect.'));
    }

    return TermPage(key: ObjectKey(device), device: device);
  }
}

class TermPage extends StatefulWidget {
  const TermPage({super.key, required this.device});

  final RemoteDevice device;

  @override
  State<TermPage> createState() => _TermPageState();
}

class _TermPageState extends State<TermPage> {
  final Terminal terminal = Terminal();
  final FocusNode _focusNode = FocusNode();
  SSHClient? _client;
  SSHSession? _session;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    final device = widget.device;
    terminal.write('Connecting to ${device.host}:${device.port}...\r\n');

    try {
      final socket = await SSHSocket.connect(device.host, device.port);
      final client = SSHClient(
        socket,
        username: device.username,
        onPasswordRequest: () => device.password,
      );
      if (!mounted) {
        client.close();
        return;
      }
      _client = client;

      final session = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );
      if (!mounted) {
        session.close();
        client.close();
        return;
      }
      _session = session;

      terminal.buffer.clear();
      terminal.buffer.setCursor(0, 0);
      terminal.write('Connected to ${device.host}.\r\n');

      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };
      terminal.onOutput = (data) {
        session.write(utf8.encode(data));
      };

      session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.write);
      session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.write);
    } catch (error) {
      if (mounted) {
        terminal.write('Connection failed: $error\r\n');
      }
    }
  }

  @override
  void dispose() {
    terminal.onOutput = null;
    _session?.close();
    _client?.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalView(
      terminal,
      autofocus: true,
      hardwareKeyboardOnly: true,
      focusNode: _focusNode,
    );
  }
}
