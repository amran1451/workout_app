// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'src/providers/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // при старте сразу синхронизируем несинкнутые, если залогинен
  final user = FirebaseAuth.instance.currentUser;
  final container = ProviderScope.containerOf(navigatorKey.currentContext ?? 
    WidgetsBinding.instance.renderViewElement!);
  if (user != null) {
    await container.read(sessionRepoProvider).syncPending(
      container.read(cloudSessionRepoProvider),
    );
  }
  runApp(const ProviderScope(child: MyApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [routeObserver],
      title: 'Workout App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: Routes.home,
      routes: Routes.routesMap,
    );
  }
}
