import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/models/attendance_session_model.dart';

void main() {
  group('AttendanceSession Model Tests', () {
    test('should create an AttendanceSession instance with required parameters', () {
      // Arrange
      final classId = 1;
      final date = DateTime(2023, 1, 1);
      
      // Act
      final session = AttendanceSession(classId: classId, date: date);
      
      // Assert
      expect(session.classId, equals(classId));
      expect(session.date, equals(date));
      expect(session.id, isNull);
      expect(session.createdAt, isNotNull);
      expect(session.updatedAt, isNotNull);
    });
    
    test('should create an AttendanceSession instance with all parameters', () {
      // Arrange
      final id = 1;
      final classId = 1;
      final date = DateTime(2023, 1, 1);
      final createdAt = DateTime(2023, 1, 1, 10, 0);
      final updatedAt = DateTime(2023, 1, 1, 11, 0);
      
      // Act
      final session = AttendanceSession(
        id: id,
        classId: classId,
        date: date,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      // Assert
      expect(session.id, equals(id));
      expect(session.classId, equals(classId));
      expect(session.date, equals(date));
      expect(session.createdAt, equals(createdAt));
      expect(session.updatedAt, equals(updatedAt));
    });
    
    test('should convert AttendanceSession to Map correctly', () {
      // Arrange
      final session = AttendanceSession(
        id: 1,
        classId: 1,
        date: DateTime(2023, 1, 1),
        createdAt: DateTime(2023, 1, 1, 10, 0),
        updatedAt: DateTime(2023, 1, 1, 11, 0),
      );
      
      // Act
      final map = session.toMap();
      
      // Assert
      expect(map['id'], equals(1));
      expect(map['class_id'], equals(1));
      expect(map['date'], equals('2023-01-01T00:00:00.000'));
      expect(map['created_at'], equals('2023-01-01T10:00:00.000'));
      expect(map['updated_at'], equals('2023-01-01T11:00:00.000'));
    });
    
    test('should create AttendanceSession from Map correctly', () {
      // Arrange
      final map = {
        'id': 1,
        'class_id': 1,
        'date': '2023-01-01T00:00:00.000',
        'created_at': '2023-01-01T10:00:00.000',
        'updated_at': '2023-01-01T11:00:00.000',
      };
      
      // Act
      final session = AttendanceSession.fromMap(map);
      
      // Assert
      expect(session.id, equals(1));
      expect(session.classId, equals(1));
      expect(session.date, equals(DateTime(2023, 1, 1)));
      expect(session.createdAt, equals(DateTime(2023, 1, 1, 10, 0)));
      expect(session.updatedAt, equals(DateTime(2023, 1, 1, 11, 0)));
    });
    
    test('should create a copy with updated fields', () {
      // Arrange
      final session = AttendanceSession(
        id: 1,
        classId: 1,
        date: DateTime(2023, 1, 1),
        createdAt: DateTime(2023, 1, 1, 10, 0),
        updatedAt: DateTime(2023, 1, 1, 11, 0),
      );
      
      // Act
      final updatedSession = session.copyWith(
        classId: 2,
        date: DateTime(2023, 1, 2),
      );
      
      // Assert
      expect(updatedSession.id, equals(1)); // Unchanged
      expect(updatedSession.classId, equals(2)); // Changed
      expect(updatedSession.date, equals(DateTime(2023, 1, 2))); // Changed
      expect(updatedSession.createdAt, equals(DateTime(2023, 1, 1, 10, 0))); // Unchanged
      expect(updatedSession.updatedAt, equals(DateTime(2023, 1, 1, 11, 0))); // Unchanged
    });
    
    test('toString should return a string representation', () {
      // Arrange
      final session = AttendanceSession(
        id: 1,
        classId: 1,
        date: DateTime(2023, 1, 1),
      );
      
      // Act
      final stringRepresentation = session.toString();
      
      // Assert
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('classId: 1'));
      expect(stringRepresentation, contains('date: 2023-01-01'));
    });
  });
}