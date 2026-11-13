import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:xterm/xterm.dart';

class VirtualKeyboardView extends StatelessWidget {
  const VirtualKeyboardView(this.keyboard, {super.key});

  final VirtualKeyboard keyboard;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: keyboard,
      builder:
          (context, child) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _modifierButton(
                label: 'Ctrl',
                selected: keyboard.ctrl,
                onPress: () => keyboard.ctrl = !keyboard.ctrl,
              ),
              const SizedBox(width: 8),
              _modifierButton(
                label: 'Alt',
                selected: keyboard.alt,
                onPress: () => keyboard.alt = !keyboard.alt,
              ),
              const SizedBox(width: 8),
              _modifierButton(
                label: 'Shift',
                selected: keyboard.shift,
                onPress: () => keyboard.shift = !keyboard.shift,
              ),
            ],
          ),
    );
  }

  Widget _modifierButton({
    required String label,
    required bool selected,
    required VoidCallback onPress,
  }) => FButton(
    variant: FButtonVariant.outline,
    size: FButtonSizeVariant.sm,
    selected: selected,
    onPress: onPress,
    child: Text(label),
  );
}

class VirtualKeyboard extends TerminalInputHandler with ChangeNotifier {
  final TerminalInputHandler _inputHandler;

  VirtualKeyboard(this._inputHandler);

  bool _ctrl = false;

  bool get ctrl => _ctrl;

  set ctrl(bool value) {
    if (_ctrl != value) {
      _ctrl = value;
      notifyListeners();
    }
  }

  bool _shift = false;

  bool get shift => _shift;

  set shift(bool value) {
    if (_shift != value) {
      _shift = value;
      notifyListeners();
    }
  }

  bool _alt = false;

  bool get alt => _alt;

  set alt(bool value) {
    if (_alt != value) {
      _alt = value;
      notifyListeners();
    }
  }

  @override
  String? call(TerminalKeyboardEvent event) {
    return _inputHandler.call(
      event.copyWith(
        ctrl: event.ctrl || _ctrl,
        shift: event.shift || _shift,
        alt: event.alt || _alt,
      ),
    );
  }
}
