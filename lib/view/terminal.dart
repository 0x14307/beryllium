import 'dart:convert';
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

const host = 'localhost';
const port = 22;
const username = 'null';
const password = 'null';

class CreateTerm extends StatelessWidget {
  const CreateTerm({super.key});

  @override
  Widget build(BuildContext context) {
    return TermPage();
  }
}

class TermPage extends StatefulWidget {
  TermPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TermPageState createState() => _TermPageState();
}

class _TermPageState extends State<TermPage> {
  late final terminal = Terminal();
  // We have to set FocusNode or else the compiler bitches at us for "no viewID"
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    initTerminal();
  }

  Future<void> initTerminal() async {
    terminal.write('Connecting...\r\n');

    final client = SSHClient(
      await SSHSocket.connect(host, port),
      username: username,
      onPasswordRequest: () => password,
    );

    terminal.write('Connected\r\n');

    final session = await client.shell(
      pty: SSHPtyConfig(width: terminal.viewWidth, height: terminal.viewHeight),
    );

    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      session.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };

    terminal.onOutput = (data) {
      session.write(utf8.encode(data));
    };

    session.stdout
        .cast<List<int>>()
        .transform(Utf8Decoder())
        .listen(terminal.write);

    session.stderr
        .cast<List<int>>()
        .transform(Utf8Decoder())
        .listen(terminal.write);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TerminalView(
            terminal,
            autofocus: true,
            hardwareKeyboardOnly: true,
            focusNode: _focusNode,
          ),
        ),
      ],
    );
  }
}
