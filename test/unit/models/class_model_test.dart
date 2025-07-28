import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/models/class_model.dart';

void main() {
  group('Class Model Tests', () {
    test('should create a Class instance with required parameters', () {
      // Arrange
      final className = 'Mathematics';
      
      // Act
      final classModel = Class(name: className);
      
      // Assert
      expect(classModel.name, equals(className));
      expect(classModel.id, isNull);
      expect(classModel.createdAt, isNotNull);
      expect(classModel.updatedAt, isNotNull);
      expect(classModel.isPinned, isFalse);
      expect(classModel.pinOrder, isNull);
      expect(classModel.studentCount, isNull);
      expect(classModel.sessionCount, isNull);
    });
    
    test('should create a Class instance with all parameters', () {
      // Arrange
      final className = 'Mathematics';
      final id = 1;
      final createdAt = DateTime(2023, 1, 1);
      final updatedAt = DateTime(2023, 1, 2);
      final isPinned = true;
      final pinOrder = 1;
      final studentCount = 25;
      final sessionCount = 10;
      
      // Act
      final classModel = Class(
        id: id,
        name: className,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isPinned: isPinned,
        pinOrder: pinOrder,
        studentCount: studentCount,
        sessionCount: sessionCount,
      );
      
      // Assert
      expect(classModel.id, equals(id));
      expect(classModel.name, equals(className));
      expect(classModel.createdAt, equals(createdAt));
      expect(classModel.updatedAt, equals(updatedAt));
      expect(classModel.isPinned, equals(isPinned));
      expect(classModel.pinOrder, equals(pinOrder));
      expect(classModel.studentCount, equals(studentCount));
      expect(classModel.sessionCount, equals(sessionCount));
    });
    
    test('should convert Class to Map correctly', () {
      // Arrange
      final classModel = Class(
        id: 1,
        name: 'Mathematics',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        isPinned: true,
        pinOrder: 1,
        studentCount: 25,
        sessionCount: 10,
      );
      
      // Act
      final map = classModel.toMap();
      
      // Assert
      expect(map['id'], equals(1));
      expect(map['name'], equals('Mathematics'));
      expect(map['created_at'], equals('2023-01-01T00:00:00.000'));
      expect(map['updated_at'], equals('2023-01-02T00:00:00.000'));
      expect(map['is_pinned'], equals(1));
      expect(map['pin_order'], equals(1));
      // Note: studentCount and sessionCount are not stored in the map
      expect(map.containsKey('student_count'), isFalse);
      expect(map.containsKey('session_count'), isFalse);
    });
    
    test('should create Class from Map correctly', () {
      // Arrange
      final map = {
        'id': 1,
        'name': 'Mathematics',
        'created_at': '2023-01-01T00:00:00.000',
        'updated_at': '2023-01-02T00:00:00.000',
        'is_pinned': 1,
        'pin_order': 1,
        'student_count': 25,
        'session_count': 10,
      };
      
      // Act
      final classModel = Class.fromMap(map);
      
      // Assert
      expect(classModel.id, equals(1));
      expect(classModel.name, equals('Mathematics'));
      expect(classModel.createdAt, equals(DateTime(2023, 1, 1)));
      expect(classModel.updatedAt, equals(DateTime(2023, 1, 2)));
      expect(classModel.isPinned, isTrue);
      expect(classModel.pinOrder, equals(1));
      expect(classModel.studentCount, equals(25));
      expect(classModel.sessionCount, equals(10));
    });
    
    test('should create a copy with updated fields', () {
      // Arrange
      final classModel = Class(
        id: 1,
        name: 'Mathematics',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        isPinned: false,
        pinOrder: null,
        studentCount: 25,
        sessionCount: 10,
      );
      
      // Act
      final updatedClass = classModel.copyWith(
        name: 'Advanced Mathematics',
        isPinned: true,
        pinOrder: 1,
        studentCount: 30,
      );
      
      // Assert
      expect(updatedClass.id, equals(1)); // Unchanged
      expect(updatedClass.name, equals('Advanced Mathematics')); // Changed
      expect(updatedClass.createdAt, equals(DateTime(2023, 1, 1))); // Unchanged
      expect(updatedClass.updatedAt, equals(DateTime(2023, 1, 2))); // Unchanged
      expect(updatedClass.isPinned, isTrue); // Changed
      expect(updatedClass.pinOrder, equals(1)); // Changed
      expect(updatedClass.studentCount, equals(30)); // Changed
      expect(updatedClass.sessionCount, equals(10)); // Unchanged
    });
    
    test('toString should return a string representation', () {
      // Arrange
      final classModel = Class(
        id: 1,
        name: 'Mathematics',
        isPinned: true,
        pinOrder: 1,
        studentCount: 25,
        sessionCount: 10,
      );
      
      // Act
      final stringRepresentation = classModel.toString();
      
      // Assert
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('name: Mathematics'));
      expect(stringRepresentation, contains('isPinned: true'));
      expect(stringRepresentation, contains('pinOrder: 1'));
      expect(stringRepresentation, contains('studentCount: 25'));
      expect(stringRepresentation, contains('sessionCount: 10'));
    });

    test('should handle pin properties correctly in toMap for unpinned class', () {
      // Arrange
      final classModel = Class(
        id: 1,
        name: 'Mathematics',
        isPinned: false,
        pinOrder: null,
      );
      
      // Act
      final map = classModel.toMap();
      
      // Assert
      expect(map['is_pinned'], equals(0));
      expect(map['pin_order'], isNull);
    });

    test('should handle pin properties correctly in fromMap for unpinned class', () {
      // Arrange
      final map = {
        'id': 1,
        'name': 'Mathematics',
        'created_at': '2023-01-01T00:00:00.000',
        'updated_at': '2023-01-02T00:00:00.000',
        'is_pinned': 0,
        'pin_order': null,
      };
      
      // Act
      final classModel = Class.fromMap(map);
      
      // Assert
      expect(classModel.isPinned, isFalse);
      expect(classModel.pinOrder, isNull);
    });

    test('should handle missing pin properties in fromMap', () {
      // Arrange
      final map = {
        'id': 1,
        'name': 'Mathematics',
        'created_at': '2023-01-01T00:00:00.000',
        'updated_at': '2023-01-02T00:00:00.000',
      };
      
      // Act
      final classModel = Class.fromMap(map);
      
      // Assert
      expect(classModel.isPinned, isFalse);
      expect(classModel.pinOrder, isNull);
    });

    test('should copy pin properties correctly', () {
      // Arrange
      final classModel = Class(
        id: 1,
        name: 'Mathematics',
        isPinned: true,
        pinOrder: 2,
      );
      
      // Act
      final copiedClass = classModel.copyWith(isPinned: false);
      
      // Assert
      expect(copiedClass.isPinned, isFalse);
      expect(copiedClass.pinOrder, equals(2)); // Should remain unchanged
      expect(copiedClass.name, equals('Mathematics')); // Other properties unchanged
    });
  });
}