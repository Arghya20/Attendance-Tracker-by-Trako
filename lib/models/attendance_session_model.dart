class AttendanceSession {
  final int? id;
  final int classId;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AttendanceSession({
    this.id,
    required this.classId,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
  
  // Create a copy of this AttendanceSession with the given fields replaced
  AttendanceSession copyWith({
    int? id,
    int? classId,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Convert AttendanceSession instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Create an AttendanceSession instance from a Map
  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'],
      classId: map['class_id'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
  
  @override
  String toString() {
    return 'AttendanceSession{id: $id, classId: $classId, date: $date}';
  }
}