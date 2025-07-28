class AttendanceRecord {
  final int? id;
  final int sessionId;
  final int studentId;
  final bool isPresent;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.isPresent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
  
  // Create a copy of this AttendanceRecord with the given fields replaced
  AttendanceRecord copyWith({
    int? id,
    int? sessionId,
    int? studentId,
    bool? isPresent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      isPresent: isPresent ?? this.isPresent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Convert AttendanceRecord instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'is_present': isPresent ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Create an AttendanceRecord instance from a Map
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      sessionId: map['session_id'],
      studentId: map['student_id'],
      isPresent: map['is_present'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
  
  @override
  String toString() {
    return 'AttendanceRecord{id: $id, sessionId: $sessionId, studentId: $studentId, isPresent: $isPresent}';
  }
}