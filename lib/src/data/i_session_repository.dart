import '../models/workout_session.dart';

/// Интерфейс репозитория сессий
abstract class ISessionRepository {
  Future<WorkoutSession> create(WorkoutSession s);
  Future<void> update(WorkoutSession s);
  Future<List<WorkoutSession>> getAll();
  Future<void> deleteSession(String sessionId);
}
