// lib/src/providers/session_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/session_repository.dart';
import '../data/cloud_session_repository.dart';
import '../models/session_entry.dart';

/// Провайдер локального SQLite-репозитория
final sessionRepoProvider =
    Provider<SessionRepository>((ref) => SessionRepository());

/// Провайдер облачного Firestore-репозитория
final cloudSessionRepoProvider =
    Provider<CloudSessionRepository>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw Exception('User not signed in');
  }
  return CloudSessionRepository(uid);
});

/// Провайдер для временных записей на экране (UI state)
final sessionEntriesProvider =
    StateProvider<List<SessionEntry>>((ref) => []);
