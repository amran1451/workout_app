import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/local/db_service.dart';

/// Синглтон локальной БД
final databaseServiceProvider =
    Provider<DatabaseService>((_) => DatabaseService.instance);

/// Провайдер для проверки сети
final connectivityProvider =
    Provider<Connectivity>((_) => Connectivity());
