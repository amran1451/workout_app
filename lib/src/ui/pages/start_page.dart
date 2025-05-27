import 'package:flutter/material.dart';
import '../../routes.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.exercises),
              child: const Text('Добавить упражнение / Мои упражнения'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.planForm),
              child: const Text('Добавить тренировку / План на неделю'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.workout),
              child: const Text('Начать тренировку'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.sessions),
              child: const Text('Мои тренировки'),
            ),
          ],
        ),
      ),
    );
  }
}