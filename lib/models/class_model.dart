class Class {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final int? pinOrder;
  
  // Computed properties (not stored in database)
  int? studentCount;
  int? sessionCount;
  
  Class({
    this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.pinOrder,
    this.studentCount,
    this.sessionCount,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
  
  // Create a copy of this Class with the given fields replaced
  Class copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    int? pinOrder,
    int? studentCount,
    int? sessionCount,
  }) {
    return Class(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      pinOrder: pinOrder ?? this.pinOrder,
      studentCount: studentCount ?? this.studentCount,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
  
  // Convert Class instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned ? 1 : 0,
      'pin_order': pinOrder,
    };
  }
  
  // Create a Class instance from a Map
  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isPinned: (map['is_pinned'] ?? 0) == 1,
      pinOrder: map['pin_order'],
      studentCount: map['student_count'],
      sessionCount: map['session_count'],
    );
  }
  
  @override
  String toString() {
    return 'Class{id: $id, name: $name, isPinned: $isPinned, pinOrder: $pinOrder, studentCount: $studentCount, sessionCount: $sessionCount}';
  }
}