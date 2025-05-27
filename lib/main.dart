// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/routes.dart';
import 'src/providers/session_provider.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: WorkoutApp()));
}

class WorkoutApp extends ConsumerWidget {
  const WorkoutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // при старте приложения синхронизируем офлайн-данные
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ref.read(sessionRepoProvider).syncPending(
        ref.read(cloudSessionRepoProvider),
      );
    }

    return MaterialApp(
      navigatorObservers: [routeObserver],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
      ],
      initialRoute: Routes.home,
      routes: Routes.routesMap,
    );
  }
}
