import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/models/attendance_record_model.dart';

void main() {
  group('AttendanceRecord Model Tests', () {
    test('should create an AttendanceRecord instance with required parameters', () {
      // Arrange
      final sessionId = 1;
      final studentId = 1;
      final isPresent = true;
      
      // Act
      final record = AttendanceRecord(
        sessionId: sessionId,
        studentId: studentId,
        isPresent: isPresent,
      );
      
      // Assert
      expect(record.sessionId, equals(sessionId));
      expect(record.studentId, equals(studentId));
      expect(record.isPresent, equals(isPresent));
      expect(record.id, isNull);
      expect(record.createdAt, isNotNull);
      expect(record.updatedAt, isNotNull);
    });
    
    test('should create an AttendanceRecord instance with all parameters', () {
      // Arrange
      final id = 1;
      final sessionId = 1;
      final studentId = 1;
      final isPresent = true;
      final createdAt = DateTime(2023, 1, 1, 10, 0);
      final updatedAt = DateTime(2023, 1, 1, 11, 0);
      
      // Act
      final record = AttendanceRecord(
        id: id,
        sessionId: sessionId,
        studentId: studentId,
        isPresent: isPresent,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      // Assert
      expect(record.id, equals(id));
      expect(record.sessionId, equals(sessionId));
      expect(record.studentId, equals(studentId));
      expect(record.isPresent, equals(isPresent));
      expect(record.createdAt, equals(createdAt));
      expect(record.updatedAt, equals(updatedAt));
    });
    
    test('should convert AttendanceRecord to Map correctly', () {
      // Arrange
      final record = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        isPresent: true,
        createdAt: DateTime(2023, 1, 1, 10, 0),
        updatedAt: DateTime(2023, 1, 1, 11, 0),
      );
      
      // Act
      final map = record.toMap();
      
      // Assert
      expect(map['id'], equals(1));
      expect(map['session_id'], equals(1));
      expect(map['student_id'], equals(1));
      expect(map['is_present'], equals(1)); // true is stored as 1
      expect(map['created_at'], equals('2023-01-01T10:00:00.000'));
      expect(map['updated_at'], equals('2023-01-01T11:00:00.000'));
    });
    
    test('should convert AttendanceRecord with isPresent=false to Map correctly', () {
      // Arrange
      final record = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        isPresent: false,
        createdAt: DateTime(2023, 1, 1, 10, 0),
        updatedAt: DateTime(2023, 1, 1, 11, 0),
      );
      
      // Act
      final map = record.toMap();
      
      // Assert
      expect(map['is_present'], equals(0)); // false is stored as 0
    });
    
    test('should create AttendanceRecord from Map correctly', () {
      // Arrange
      final map = {
        'id': 1,
        'session_id': 1,
        'student_id': 1,
        'is_present': 1, // 1 represents true
        'created_at': '2023-01-01T10:00:00.000',
        'updated_at': '2023-01-01T11:00:00.000',
      };
      
      // Act
      final record = AttendanceRecord.fromMap(map);
      
      // Assert
      expect(record.id, equals(1));
      expect(record.sessionId, equals(1));
      expect(record.studentId, equals(1));
      expect(record.isPresent, isTrue);
      expect(record.createdAt, equals(DateTime(2023, 1, 1, 10, 0)));
      expect(record.updatedAt, equals(DateTime(2023, 1, 1, 11, 0)));
    });
    
    test('should create AttendanceRecord from Map with is_present=0 correctly', () {
      // Arrange
      final map = {
        'id': 1,
        'session_id': 1,
        'student_id': 1,
        'is_present': 0, // 0 represents false
        'created_at': '2023-01-01T10:00:00.000',
        'updated_at': '2023-01-01T11:00:00.000',
      };
      
      // Act
      final record = AttendanceRecord.fromMap(map);
      
      // Assert
      expect(record.isPresent, isFalse);
    });
    
    test('should create a copy with updated fields', () {
      // Arrange
      final record = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        isPresent: true,
        createdAt: DateTime(2023, 1, 1, 10, 0),
        updatedAt: DateTime(2023, 1, 1, 11, 0),
      );
      
      // Act
      final updatedRecord = record.copyWith(
        isPresent: false,
      );
      
      // Assert
      expect(updatedRecord.id, equals(1)); // Unchanged
      expect(updatedRecord.sessionId, equals(1)); // Unchanged
      expect(updatedRecord.studentId, equals(1)); // Unchanged
      expect(updatedRecord.isPresent, isFalse); // Changed
      expect(updatedRecord.createdAt, equals(DateTime(2023, 1, 1, 10, 0))); // Unchanged
      expect(updatedRecord.updatedAt, equals(DateTime(2023, 1, 1, 11, 0))); // Unchanged
    });
    
    test('toString should return a string representation', () {
      // Arrange
      final record = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        isPresent: true,
      );
      
      // Act
      final stringRepresentation = record.toString();
      
      // Assert
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('sessionId: 1'));
      expect(stringRepresentation, contains('studentId: 1'));
      expect(stringRepresentation, contains('isPresent: true'));
    });
  });
}