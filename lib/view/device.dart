import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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

  Map<String, Object> toJson() => {
    'username': username,
    'host': host,
    'password': password,
    'port': port,
  };

  factory RemoteDevice.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['username'] is! String ||
        value['host'] is! String ||
        value['password'] is! String ||
        value['port'] is! int) {
      throw const FormatException('Invalid saved device');
    }

    return RemoteDevice(
      username: value['username'] as String,
      host: value['host'] as String,
      password: value['password'] as String,
      port: value['port'] as int,
    );
  }
}

class deviceUI extends StatefulWidget {
  const deviceUI({required this.animation, super.key});

  final Animation<double> animation;

  @override
  State<deviceUI> createState() => _deviceUIState();
}

class _deviceUIState extends State<deviceUI> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _hostController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();

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
    return FDialog(
      animation: widget.animation,
      builder:
          (context, style) => Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Add Device', style: style.titleTextStyle),
                    const SizedBox(height: 16),
                    FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: _userController,
                      ),
                      label: const Text('User'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: _hostController,
                      ),
                      label: const Text('Host'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: _passwordController,
                      ),
                      label: const Text('Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: _portController,
                      ),
                      label: const Text('Port'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_parsePort(value) == null) {
                          return 'Enter a port from 1 to 65535';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FButton(
                          variant: FButtonVariant.ghost,
                          onPress: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FButton(onPress: _addDevice, child: const Text('Add')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
