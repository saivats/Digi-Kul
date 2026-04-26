import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/background/background_tasks.dart';
import 'core/storage/isar_service.dart';
import 'core/storage/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("🚀 Starting Digi-Kul Initialization...");

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    debugPrint('DEBUG: Initializing Firebase...');
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    debugPrint('DEBUG: Firebase initialized');
  } catch (e) {
    debugPrint('DEBUG: Firebase initialization failed (ignored): $e');
  }

  try {
    debugPrint("💾 Initializing Preferences...");
    await PreferencesService.init();
    debugPrint("✅ Preferences Ready");
  } catch (e) {
    debugPrint("❌ Preferences init failed: $e");
  }

  try {
    debugPrint('DEBUG: Initializing Isar...');
    await IsarService.instance;
    debugPrint('DEBUG: Isar initialized');
  } catch (e) {
    debugPrint('DEBUG: Isar initialization failed: $e');
  }

  try {
    debugPrint("👷 Initializing Workmanager...");
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      refreshCacheTaskName,
      refreshCacheTaskName,
      frequency: const Duration(hours: 4),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    debugPrint("✅ Workmanager Ready");
  } catch (e) {
    debugPrint("⚠️ Workmanager init failed: $e");
  }

  debugPrint("🎨 Launching UI...");
  runApp(
    const ProviderScope(
      child: DigikulApp(),
    ),
  );
}
