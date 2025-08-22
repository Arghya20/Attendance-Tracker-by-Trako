import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:attendance_tracker/providers/student_provider.dart';
import 'package:attendance_tracker/repositories/student_repository.dart';
import 'package:attendance_tracker/models/models.dart';

import 'student_provider_cache_test.mocks.dart';

@GenerateMocks([StudentRepository])
void main() {
  group('StudentProvider Cache Tests', () {
    late StudentProvider provider;
    late MockStudentRepository mockRepository;

    setUp(() {
      mockRepository = MockStudentRepository();
      provider = StudentProvider();
    });

    test('should invalidate cache when invalidateAttendanceCache is called', () async {
      // Arrange
      const classId = 1;
      final students = [
        Student(
          id: 1,
          classId: classId,
          name: 'Test Student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
      ];

      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async => students);

      // Load students first to populate cache
      await provider.loadStudents(classId);
      expect(provider.students, hasLength(1));

      // Invalidate cache
      provider.invalidateAttendanceCache(classId);

      // Load students again - should make new repository call
      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async => []);

      await provider.loadStudents(classId);

      // Verify repository was called twice (once for initial load, once after invalidation)
      verify(mockRepository.getStudentsWithAttendanceStats(classId)).called(2);
    });

    test('should refresh attendance stats for current class', () async {
      // Arrange
      const classId = 1;
      final students = [
        Student(
          id: 1,
          classId: classId,
          name: 'Test Student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
      ];

      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async => students);

      // Load students to set current class
      await provider.loadStudents(classId);

      // Act
      await provider.refreshAttendanceStats(classId);

      // Assert - repository should be called twice (initial load + refresh)
      verify(mockRepository.getStudentsWithAttendanceStats(classId)).called(2);
    });

    test('should not refresh attendance stats for different class', () async {
      // Arrange
      const classId1 = 1;
      const classId2 = 2;
      final students = [
        Student(
          id: 1,
          classId: classId1,
          name: 'Test Student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
      ];

      when(mockRepository.getStudentsWithAttendanceStats(classId1))
          .thenAnswer((_) async => students);

      // Load students for class 1
      await provider.loadStudents(classId1);

      // Try to refresh for class 2
      await provider.refreshAttendanceStats(classId2);

      // Assert - repository should only be called once (for initial load)
      verify(mockRepository.getStudentsWithAttendanceStats(classId1)).called(1);
      verifyNever(mockRepository.getStudentsWithAttendanceStats(classId2));
    });

    test('should handle refresh timeout gracefully', () async {
      // Arrange
      const classId = 1;
      final students = [
        Student(
          id: 1,
          classId: classId,
          name: 'Test Student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
      ];

      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async => students);

      // Load students to set current class
      await provider.loadStudents(classId);

      // Mock a slow response that will timeout
      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 3));
        return students;
      });

      // Act
      await provider.refreshAttendanceStats(classId);

      // Assert - should have error set
      expect(provider.error, contains('Refresh timeout'));
    });

    test('should handle refresh errors gracefully', () async {
      // Arrange
      const classId = 1;
      final students = [
        Student(
          id: 1,
          classId: classId,
          name: 'Test Student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
      ];

      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async => students);

      // Load students to set current class
      await provider.loadStudents(classId);

      // Mock an error response
      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenThrow(Exception('Database error'));

      // Act
      await provider.refreshAttendanceStats(classId);

      // Assert - should have error set
      expect(provider.error, contains('Failed to refresh attendance data'));
    });

    test('should respect cache invalidation in loadStudents', () async {
      // Arrange
      const classId = 1;
      final students = [
        Student(
          id: 1,
          classId: classId,
          name: 'Test Student',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attendancePercentage: 80.0,
        ),
      ];

      when(mockRepository.getStudentsWithAttendanceStats(classId))
          .thenAnswer((_) async => students);

      // Load students first time
      await provider.loadStudents(classId);

      // Load again immediately - should use cache
      await provider.loadStudents(classId);
      verify(mockRepository.getStudentsWithAttendanceStats(classId)).called(1);

      // Invalidate cache and load again
      provider.invalidateAttendanceCache(classId);
      await provider.loadStudents(classId);

      // Should make new repository call
      verify(mockRepository.getStudentsWithAttendanceStats(classId)).called(2);
    });
  });
}