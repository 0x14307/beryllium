import 'package:flutter/material.dart';

import '../func/ssh.dart';

class deviceUI extends StatefulWidget {
  const deviceUI({super.key});

  @override
  _deviceUIState createState() => _deviceUIState();
}

final userInput = TextEditingController();
final hostInput = TextEditingController();
final passInput = TextEditingController();
final portInput = TextEditingController();

List<String> inputs = ["3"];

List<String> getInput() {
  List<String> inputs = [
    userInput.text,
    hostInput.text,
    passInput.text,
    portInput.text,
  ];
  print(inputs);

  return inputs;
}

var textInputs = getInput();

class _deviceUIState extends State<deviceUI> {
  // We require set up before getting the input.

  @override // Make this not zoomed in (why the hell is this happening?)
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Device"),
      content: Container(
        child: Column(
          children: [
            TextField(
              controller: userInput,
              decoration: InputDecoration(labelText: "User"),
            ),
            TextField(
              controller: hostInput,
              decoration: InputDecoration(labelText: "Host"),
            ),
            TextField(
              controller: passInput,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            TextField(
              controller: portInput,
              decoration: InputDecoration(labelText: "Port"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: () => getInput(), child: const Text('Add')),
      ],
    );
  }
}
