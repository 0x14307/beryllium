import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'view/ui.dart';

void main() {
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.neutral.dark.desktop;

    return WidgetsApp(
      title: 'beryllium',
      color: theme.colors.background,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      pageRouteBuilder:
          <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) {
              return builder(context);
            },
          ),
      builder: (context, child) {
        return FTheme(
          data: theme,
          child: FToaster(
            child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      home: navUI(),
    );
  }
}
