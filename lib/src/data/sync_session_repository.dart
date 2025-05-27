import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_session_repository.dart';
import 'session_repository.dart';
import 'cloud_session_repository.dart';
import '../models/workout_session.dart';

/// Репозиторий «локально + облако» для тренировочных сессий
class SyncSessionRepository implements ISessionRepository {
  final SessionRepository local;
  final CloudSessionRepository cloud;
  final Connectivity connectivity;

  SyncSessionRepository(this.local, this.cloud, this.connectivity);

  Future<bool> get _hasNetwork async {
    final res = await connectivity.checkConnectivity();
    return res != ConnectivityResult.none;
  }

  @override
  Future<WorkoutSession> create(WorkoutSession s) async {
    final localSession = await local.create(s);
    if (await _hasNetwork) {
      try {
        await cloud.create(localSession);
      } catch (_) {}
    }
    return localSession;
  }

  @override
  Future<void> update(WorkoutSession s) async {
    await local.update(s);
    if (await _hasNetwork) {
      try {
        await cloud.update(s);
      } catch (_) {}
    }
  }

  @override
  Future<List<WorkoutSession>> getAll() => local.getAll();

  @override
  Future<void> deleteSession(String sessionId) async {
    await local.deleteSession(sessionId);
    if (await _hasNetwork) {
      try {
        await cloud.deleteSession(sessionId);
      } catch (_) {}
    }
  }
}
