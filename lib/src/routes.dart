// lib/routes.dart
import 'package:flutter/material.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/exercises_page.dart';
import 'ui/pages/exercise_form_page.dart';
import 'ui/pages/plan_form_page.dart';
import 'ui/pages/sessions_page.dart';
import 'ui/pages/workout_page.dart';

class Routes {
  static const String home = '/';
  static const String exercises = '/exercises';
  static const String exerciseForm = '/exerciseForm';
  static const String plan = '/plan';
  static const String sessions = '/sessions';
  static const String workout = '/workout';

  static final Map<String, WidgetBuilder> routesMap = {
    home: (context) => const HomePage(),
    exercises: (context) => const ExercisesPage(),
    exerciseForm: (context) => const ExerciseFormPage(),
    plan: (context) => const PlanFormPage(),
    sessions: (context) => const SessionsPage(),
    workout: (context) => const WorkoutPage(),
  };
}
