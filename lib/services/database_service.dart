import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.databaseName);

      // Enable foreign key support
      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
  
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create classes table
      await db.execute('''
        CREATE TABLE ${AppConstants.classTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_pinned INTEGER DEFAULT 0,
          pin_order INTEGER DEFAULT NULL
        )
      ''');

      // Create students table
      await db.execute('''
        CREATE TABLE ${AppConstants.studentTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          roll_number TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (class_id) REFERENCES ${AppConstants.classTable} (id) ON DELETE CASCADE
        )
      ''');

      // Create attendance sessions table
      await db.execute('''
        CREATE TABLE ${AppConstants.attendanceSessionTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (class_id) REFERENCES ${AppConstants.classTable} (id) ON DELETE CASCADE,
          UNIQUE(class_id, date)
        )
      ''');

      // Create attendance records table
      await db.execute('''
        CREATE TABLE ${AppConstants.attendanceRecordTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          student_id INTEGER NOT NULL,
          is_present INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (session_id) REFERENCES ${AppConstants.attendanceSessionTable} (id) ON DELETE CASCADE,
          FOREIGN KEY (student_id) REFERENCES ${AppConstants.studentTable} (id) ON DELETE CASCADE,
          UNIQUE(session_id, student_id)
        )
      ''');
      
      // Create indexes for better performance
      await db.execute(
        'CREATE INDEX idx_student_class_id ON ${AppConstants.studentTable} (class_id)'
      );
      await db.execute(
        'CREATE INDEX idx_session_class_id ON ${AppConstants.attendanceSessionTable} (class_id)'
      );
      await db.execute(
        'CREATE INDEX idx_session_date ON ${AppConstants.attendanceSessionTable} (date)'
      );
      await db.execute(
        'CREATE INDEX idx_record_session_id ON ${AppConstants.attendanceRecordTable} (session_id)'
      );
      await db.execute(
        'CREATE INDEX idx_record_student_id ON ${AppConstants.attendanceRecordTable} (student_id)'
      );
      await db.execute(
        'CREATE INDEX idx_record_presence ON ${AppConstants.attendanceRecordTable} (is_present)'
      );
      await db.execute(
        'CREATE INDEX idx_class_pinned ON ${AppConstants.classTable} (is_pinned)'
      );
      await db.execute(
        'CREATE INDEX idx_class_pin_order ON ${AppConstants.classTable} (pin_order)'
      );
    } catch (e) {
      debugPrint('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // Handle database migrations here when schema changes
      if (oldVersion < 2) {
        // Add pin functionality columns to classes table
        await db.execute('ALTER TABLE ${AppConstants.classTable} ADD COLUMN is_pinned INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE ${AppConstants.classTable} ADD COLUMN pin_order INTEGER DEFAULT NULL');
        
        // Create indexes for pin functionality
        await db.execute(
          'CREATE INDEX idx_class_pinned ON ${AppConstants.classTable} (is_pinned)'
        );
        await db.execute(
          'CREATE INDEX idx_class_pin_order ON ${AppConstants.classTable} (pin_order)'
        );
      }
    } catch (e) {
      debugPrint('Error upgrading database: $e');
      rethrow;
    }
  }

  // Helper method to get current datetime in ISO format
  String getCurrentDateTime() {
    return DateTime.now().toIso8601String();
  }
  
  // Generic CRUD operations
  
  // Insert a record into a table
  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error inserting into $table: $e');
      rethrow;
    }
  }
  
  // Get all records from a table
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      final db = await database;
      return await db.query(table);
    } catch (e) {
      debugPrint('Error getting all records from $table: $e');
      rethrow;
    }
  }
  
  // Get a record by ID
  Future<Map<String, dynamic>?> getById(String table, int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting record by ID from $table: $e');
      rethrow;
    }
  }
  
  // Update a record
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    try {
      final db = await database;
      return await db.update(
        table,
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating record in $table: $e');
      rethrow;
    }
  }
  
  // Delete a record
  Future<int> delete(String table, int id) async {
    try {
      final db = await database;
      return await db.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting record from $table: $e');
      rethrow;
    }
  }
  
  // Custom queries
  Future<List<Map<String, dynamic>>> rawQuery(String query, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawQuery(query, arguments);
    } catch (e) {
      debugPrint('Error executing raw query: $e');
      rethrow;
    }
  }
  
  // Execute a batch of operations
  Future<List<dynamic>> batch(Function(Batch batch) operations) async {
    try {
      final db = await database;
      final batch = db.batch();
      operations(batch);
      return await batch.commit();
    } catch (e) {
      debugPrint('Error executing batch operations: $e');
      rethrow;
    }
  }
  
  // Close the database
  Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
    } catch (e) {
      debugPrint('Error closing database: $e');
      rethrow;
    }
  }
  
  // For testing purposes only
  @visibleForTesting
  static void setDatabaseForTesting(Database database) {
    _database = database;
  }
}