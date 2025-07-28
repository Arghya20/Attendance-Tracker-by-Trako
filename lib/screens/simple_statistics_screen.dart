import 'package:flutter/material.dart';
import 'package:attendance_tracker/models/models.dart';

class SimpleStatisticsScreen extends StatelessWidget {
  final Class classItem;
  
  const SimpleStatisticsScreen({
    super.key,
    required this.classItem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Statistics'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Class: ${classItem.name}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'This is a simple statistics screen',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}