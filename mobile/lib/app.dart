import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/preferences.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'widgets/offline_banner.dart';

class DigikulApp extends ConsumerWidget {
  const DigikulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDark = PreferencesService.isDarkMode;

    return MaterialApp.router(
      title: 'Digi-Kul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
