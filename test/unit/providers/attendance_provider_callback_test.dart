import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:attendance_tracker/providers/attendance_provider.dart';
import 'package:attendance_tracker/repositories/attendance_repository.dart';
import 'package:attendance_tracker/models/models.dart';

import 'attendance_provider_callback_test.mocks.dart';

@GenerateMocks([AttendanceRepository])
void main() {
  group('AttendanceProvider Callback Tests', () {
    late AttendanceProvider provider;
    late MockAttendanceRepository mockRepository;
    late bool callbackTriggered;
    late int callbackClassId;

    setUp(() {
      mockRepository = MockAttendanceRepository();
      provider = AttendanceProvider();
      // Use reflection to set the private repository field
      provider.onAttendanceUpdated = (classId) {
        callbackTriggered = true;
        callbackClassId = classId;
      };
      callbackTriggered = false;
      callbackClassId = -1;
    });

    test('should trigger callback when attendance is saved successfully', () async {
      // Arrange
      const sessionId = 1;
      const classId = 10;
      final session = AttendanceSession(
        id: sessionId,
        classId: classId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      final records = [
        AttendanceRecord(
          sessionId: sessionId,
          studentId: 1,
          isPresent: true,
        ),
      ];

      when(mockRepository.getSessionById(sessionId))
          .thenAnswer((_) async => session);
      when(mockRepository.deleteAttendanceRecords(sessionId))
          .thenAnswer((_) async => true);
      when(mockRepository.saveAttendanceRecords(sessionId, records))
          .thenAnswer((_) async => true);
      when(mockRepository.getRecordsBySessionId(sessionId))
          .thenAnswer((_) async => records);
      when(mockRepository.getAttendanceWithStudentInfo(sessionId))
          .thenAnswer((_) async => []);

      // Act
      final result = await provider.saveAttendanceRecords(sessionId, records);

      // Assert
      expect(result, isTrue);
      expect(callbackTriggered, isTrue);
      expect(callbackClassId, equals(classId));
    });

    test('should not trigger callback when attendance save fails', () async {
      // Arrange
      const sessionId = 1;
      const classId = 10;
      final session = AttendanceSession(
        id: sessionId,
        classId: classId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      final records = [
        AttendanceRecord(
          sessionId: sessionId,
          studentId: 1,
          isPresent: true,
        ),
      ];

      when(mockRepository.getSessionById(sessionId))
          .thenAnswer((_) async => session);
      when(mockRepository.deleteAttendanceRecords(sessionId))
          .thenAnswer((_) async => true);
      when(mockRepository.saveAttendanceRecords(sessionId, records))
          .thenAnswer((_) async => false);

      // Act
      final result = await provider.saveAttendanceRecords(sessionId, records);

      // Assert
      expect(result, isFalse);
      expect(callbackTriggered, isFalse);
    });

    test('should not trigger callback when session is null', () async {
      // Arrange
      const sessionId = 1;
      final records = [
        AttendanceRecord(
          sessionId: sessionId,
          studentId: 1,
          isPresent: true,
        ),
      ];

      when(mockRepository.getSessionById(sessionId))
          .thenAnswer((_) async => null);

      // Act
      final result = await provider.saveAttendanceRecords(sessionId, records);

      // Assert
      expect(result, isFalse);
      expect(callbackTriggered, isFalse);
    });

    test('should handle callback being null gracefully', () async {
      // Arrange
      provider.onAttendanceUpdated = null;
      const sessionId = 1;
      const classId = 10;
      final session = AttendanceSession(
        id: sessionId,
        classId: classId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      final records = [
        AttendanceRecord(
          sessionId: sessionId,
          studentId: 1,
          isPresent: true,
        ),
      ];

      when(mockRepository.getSessionById(sessionId))
          .thenAnswer((_) async => session);
      when(mockRepository.deleteAttendanceRecords(sessionId))
          .thenAnswer((_) async => true);
      when(mockRepository.saveAttendanceRecords(sessionId, records))
          .thenAnswer((_) async => true);
      when(mockRepository.getRecordsBySessionId(sessionId))
          .thenAnswer((_) async => records);
      when(mockRepository.getAttendanceWithStudentInfo(sessionId))
          .thenAnswer((_) async => []);

      // Act & Assert - should not throw
      expect(() async => await provider.saveAttendanceRecords(sessionId, records),
          returnsNormally);
    });

    test('notifyAttendanceUpdated should call callback when set', () {
      // Arrange
      const classId = 5;

      // Act
      provider.notifyAttendanceUpdated(classId);

      // Assert
      expect(callbackTriggered, isTrue);
      expect(callbackClassId, equals(classId));
    });

    test('notifyAttendanceUpdated should handle null callback gracefully', () {
      // Arrange
      provider.onAttendanceUpdated = null;
      const classId = 5;

      // Act & Assert - should not throw
      expect(() => provider.notifyAttendanceUpdated(classId), returnsNormally);
    });
  });
}