import 'package:flutter/material.dart';

class RemoteDevice {
  const RemoteDevice({
    required this.username,
    required this.host,
    required this.password,
    required this.port,
  });

  final String username;
  final String host;
  final String password;
  final int port;
}

class deviceUI extends StatefulWidget {
  const deviceUI({super.key});

  @override
  State<deviceUI> createState() => _deviceUIState();
}

class _deviceUIState extends State<deviceUI> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _hostController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: 'Default: 22');

  @override
  void dispose() {
    _userController.dispose();
    _hostController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _addDevice() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      RemoteDevice(
        username: _userController.text.trim(),
        host: _hostController.text.trim(),
        password: _passwordController.text,
        port: _parsePort(_portController.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Device'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'User'),
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: 'Host'),
                validator: _requiredValidator,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
                validator: (value) {
                  if (_parsePort(value) == null) {
                    return 'Enter a port from 1 to 65535';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _addDevice, child: const Text('Add')),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  int? _parsePort(String? value) {
    final text = value?.trim();
    final port = text == 'Default: 22' ? 22 : int.tryParse(text ?? '');
    if (port == null || port < 1 || port > 65535) return null;
    return port;
  }
}
