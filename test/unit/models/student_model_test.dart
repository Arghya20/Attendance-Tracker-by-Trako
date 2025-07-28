import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/models/student_model.dart';

void main() {
  group('Student Model Tests', () {
    test('should create a Student instance with required parameters', () {
      // Arrange
      final studentName = 'John Doe';
      final classId = 1;
      
      // Act
      final student = Student(name: studentName, classId: classId);
      
      // Assert
      expect(student.name, equals(studentName));
      expect(student.classId, equals(classId));
      expect(student.id, isNull);
      expect(student.rollNumber, isNull);
      expect(student.createdAt, isNotNull);
      expect(student.updatedAt, isNotNull);
      expect(student.attendancePercentage, isNull);
    });
    
    test('should create a Student instance with all parameters', () {
      // Arrange
      final studentName = 'John Doe';
      final classId = 1;
      final id = 1;
      final rollNumber = 'A123';
      final createdAt = DateTime(2023, 1, 1);
      final updatedAt = DateTime(2023, 1, 2);
      final attendancePercentage = 85.5;
      
      // Act
      final student = Student(
        id: id,
        name: studentName,
        classId: classId,
        rollNumber: rollNumber,
        createdAt: createdAt,
        updatedAt: updatedAt,
        attendancePercentage: attendancePercentage,
      );
      
      // Assert
      expect(student.id, equals(id));
      expect(student.name, equals(studentName));
      expect(student.classId, equals(classId));
      expect(student.rollNumber, equals(rollNumber));
      expect(student.createdAt, equals(createdAt));
      expect(student.updatedAt, equals(updatedAt));
      expect(student.attendancePercentage, equals(attendancePercentage));
    });
    
    test('should convert Student to Map correctly', () {
      // Arrange
      final student = Student(
        id: 1,
        name: 'John Doe',
        classId: 1,
        rollNumber: 'A123',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        attendancePercentage: 85.5,
      );
      
      // Act
      final map = student.toMap();
      
      // Assert
      expect(map['id'], equals(1));
      expect(map['name'], equals('John Doe'));
      expect(map['class_id'], equals(1));
      expect(map['roll_number'], equals('A123'));
      expect(map['created_at'], equals('2023-01-01T00:00:00.000'));
      expect(map['updated_at'], equals('2023-01-02T00:00:00.000'));
      // Note: attendancePercentage is not stored in the map
      expect(map.containsKey('attendance_percentage'), isFalse);
    });
    
    test('should create Student from Map correctly', () {
      // Arrange
      final map = {
        'id': 1,
        'name': 'John Doe',
        'class_id': 1,
        'roll_number': 'A123',
        'created_at': '2023-01-01T00:00:00.000',
        'updated_at': '2023-01-02T00:00:00.000',
        'attendance_percentage': 85.5,
      };
      
      // Act
      final student = Student.fromMap(map);
      
      // Assert
      expect(student.id, equals(1));
      expect(student.name, equals('John Doe'));
      expect(student.classId, equals(1));
      expect(student.rollNumber, equals('A123'));
      expect(student.createdAt, equals(DateTime(2023, 1, 1)));
      expect(student.updatedAt, equals(DateTime(2023, 1, 2)));
      expect(student.attendancePercentage, equals(85.5));
    });
    
    test('should create a copy with updated fields', () {
      // Arrange
      final student = Student(
        id: 1,
        name: 'John Doe',
        classId: 1,
        rollNumber: 'A123',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
        attendancePercentage: 85.5,
      );
      
      // Act
      final updatedStudent = student.copyWith(
        name: 'Jane Doe',
        rollNumber: 'B456',
        attendancePercentage: 90.0,
      );
      
      // Assert
      expect(updatedStudent.id, equals(1)); // Unchanged
      expect(updatedStudent.name, equals('Jane Doe')); // Changed
      expect(updatedStudent.classId, equals(1)); // Unchanged
      expect(updatedStudent.rollNumber, equals('B456')); // Changed
      expect(updatedStudent.createdAt, equals(DateTime(2023, 1, 1))); // Unchanged
      expect(updatedStudent.updatedAt, equals(DateTime(2023, 1, 2))); // Unchanged
      expect(updatedStudent.attendancePercentage, equals(90.0)); // Changed
    });
    
    test('toString should return a string representation', () {
      // Arrange
      final student = Student(
        id: 1,
        name: 'John Doe',
        classId: 1,
        rollNumber: 'A123',
        attendancePercentage: 85.5,
      );
      
      // Act
      final stringRepresentation = student.toString();
      
      // Assert
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('classId: 1'));
      expect(stringRepresentation, contains('name: John Doe'));
      expect(stringRepresentation, contains('rollNumber: A123'));
      expect(stringRepresentation, contains('attendancePercentage: 85.5'));
    });
  });
}