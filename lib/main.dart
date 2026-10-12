import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_gate.dart';
import 'services/mark_store.dart';
import 'state/cleaner_state.dart';
import 'state/settings.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings.instance;
  await settings.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => CleanerState(MarkStore(), settings),
        ),
      ],
      child: const GalleryCleanerApp(),
    ),
  );
}

class GalleryCleanerApp extends StatelessWidget {
  const GalleryCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '图库清道夫',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: const HomeGate(),
    );
  }
}
