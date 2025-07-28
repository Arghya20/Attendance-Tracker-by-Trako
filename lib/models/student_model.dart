class Student {
  final int? id;
  final int classId;
  final String name;
  final String? rollNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed properties (not stored in database)
  double? attendancePercentage;
  
  Student({
    this.id,
    required this.classId,
    required this.name,
    this.rollNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.attendancePercentage,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
  
  // Create a copy of this Student with the given fields replaced
  Student copyWith({
    int? id,
    int? classId,
    String? name,
    String? rollNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? attendancePercentage,
  }) {
    return Student(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
  
  // Convert Student instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'roll_number': rollNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Create a Student instance from a Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      classId: map['class_id'],
      name: map['name'],
      rollNumber: map['roll_number'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      attendancePercentage: map['attendance_percentage'],
    );
  }
  
  @override
  String toString() {
    return 'Student{id: $id, classId: $classId, name: $name, rollNumber: $rollNumber, attendancePercentage: $attendancePercentage}';
  }
}