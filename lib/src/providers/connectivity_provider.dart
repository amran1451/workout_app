import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Позволит нам проверять, есть ли сеть
final connectivityProvider = Provider<Connectivity>((_) => Connectivity());
