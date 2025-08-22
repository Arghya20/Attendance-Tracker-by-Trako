import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/screens/class_detail_screen.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/student_list_item.dart';
import 'package:attendance_tracker/services/navigation_service.dart';

import 'class_detail_screen_refresh_test.mocks.dart';

@GenerateMocks([
  ClassProvider,
  StudentProvider,
  AttendanceProvider,
  NavigationService,
])
void main() {
  group('ClassDetailScreen Refresh Tests', () {
    late MockClassProvider mockClassProvider;
    late MockStudentProvider mockStudentProvider;
    late MockAttendanceProvider mockAttendanceProvider;
    late Class testClass;
    late List<Student> testStudents;

    setUp(() {
      mockClassProvider = MockClassProvider();
      mockStudentProvider = MockStudentProvider();
      mockAttendanceProvider = MockAttendanceProvider();

      testClass = Class(
        id: 1,
        name: 'Test Class',
        description: 'Test Description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testStudents = [
        Student(
          id: 1,
          classId: 1,
          name: 'Student 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
        Student(
          id: 2,
          classId: 1,
          name: 'Student 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 90.0,
        ),
      ];

      // Setup default mock behaviors
      when(mockClassProvider.selectedClass).thenReturn(testClass);
      when(mockStudentProvider.students).thenReturn(testStudents);
      when(mockStudentProvider.isLoading).thenReturn(false);
      when(mockStudentProvider.error).thenReturn(null);
      when(mockStudentProvider.currentClassId).thenReturn(1);
      when(mockAttendanceProvider.isLoading).thenReturn(false);
      when(mockAttendanceProvider.error).thenReturn(null);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClassProvider>.value(value: mockClassProvider),
            ChangeNotifierProvider<StudentProvider>.value(value: mockStudentProvider),
            ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendanceProvider),
          ],
          child: const ClassDetailScreen(),
        ),
      );
    }

    testWidgets('should set up attendance callback listener on init', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      verify(mockStudentProvider.loadStudents(1)).called(1);
      // Verify that onAttendanceUpdated callback is set (indirectly through behavior)
    });

    testWidgets('should display student progress indicators', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(StudentListItem), findsNWidgets(2));
      expect(find.text('Student 1'), findsOneWidget);
      expect(find.text('Student 2'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
    });

    testWidgets('should handle refresh errors gracefully', (tester) async {
      // Arrange
      when(mockStudentProvider.error).thenReturn('Network error');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate error during refresh
      when(mockStudentProvider.refreshAttendanceStats(1))
          .thenAnswer((_) async {
        when(mockStudentProvider.error).thenReturn('Refresh failed');
      });

      // Trigger refresh by calling the callback
      final state = tester.state<_ClassDetailScreenState>(
        find.byType(ClassDetailScreen),
      );
      state._onAttendanceUpdated(1);

      await tester.pumpAndSettle();

      // Assert
      verify(mockStudentProvider.invalidateAttendanceCache(1)).called(1);
      verify(mockStudentProvider.refreshAttendanceStats(1)).called(1);
    });

    testWidgets('should refresh data when attendance is updated', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate attendance update
      final state = tester.state<_ClassDetailScreenState>(
        find.byType(ClassDetailScreen),
      );
      state._onAttendanceUpdated(1);

      await tester.pumpAndSettle();

      // Assert
      verify(mockStudentProvider.invalidateAttendanceCache(1)).called(1);
      verify(mockStudentProvider.refreshAttendanceStats(1)).called(1);
    });

    testWidgets('should handle manual refresh', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Assert
      verify(mockStudentProvider.loadStudents(1)).called(2); // Initial + manual refresh
    });

    testWidgets('should preserve UI state during refresh', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to test scroll position preservation
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -100));
      await tester.pumpAndSettle();

      // Trigger refresh
      final state = tester.state<_ClassDetailScreenState>(
        find.byType(ClassDetailScreen),
      );
      state._onAttendanceUpdated(1);

      await tester.pumpAndSettle();

      // Assert that the list is still present and functional
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(StudentListItem), findsNWidgets(2));
    });

    testWidgets('should show loading state during refresh', (tester) async {
      // Arrange
      when(mockStudentProvider.isLoading).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should update progress indicators after refresh', (tester) async {
      // Arrange - initial state
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial percentages
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);

      // Update mock data to simulate attendance change
      final updatedStudents = [
        Student(
          id: 1,
          classId: 1,
          name: 'Student 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 85.0, // Changed from 80.0
        ),
        Student(
          id: 2,
          classId: 1,
          name: 'Student 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 95.0, // Changed from 90.0
        ),
      ];

      when(mockStudentProvider.students).thenReturn(updatedStudents);

      // Trigger refresh
      final state = tester.state<_ClassDetailScreenState>(
        find.byType(ClassDetailScreen),
      );
      state._onAttendanceUpdated(1);

      // Rebuild widget with updated data
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert updated percentages are displayed
      expect(find.text('85.0%'), findsOneWidget);
      expect(find.text('95.0%'), findsOneWidget);
      expect(find.text('80.0%'), findsNothing);
      expect(find.text('90.0%'), findsNothing);
    });
  });
}