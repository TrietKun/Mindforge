import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/i18n/app_lang.dart';
import 'core/theme/app_theme.dart';
import 'core/tutorial.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await TutorialStore.load();
  runApp(const MindForgeApp());
}

class MindForgeApp extends StatelessWidget {
  const MindForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when the language changes.
    return ValueListenableBuilder<AppLang>(
      valueListenable: appLang,
      builder: (context, lang, _) => MaterialApp(
        title: 'MindForge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        // Key on the language so the whole tree rebuilds when it changes.
        home: HomeScreen(key: ValueKey(lang)),
      ),
    );
  }
}
