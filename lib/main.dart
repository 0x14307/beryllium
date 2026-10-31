import 'package:flutter/material.dart';
import 'view/ui.dart';

void main() {
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'beryllium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.blue,
          primary: Colors.lightBlue,
        ),
      ),
      home: DefaultTabController(length: 2, child: navUI()),
    );
  }
}
