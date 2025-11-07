import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';
import 'package:attendance_tracker/repositories/repositories.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// A service locator for dependency injection
class ServiceLocator {
  // Singleton instance
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  // Factory constructor
  factory ServiceLocator() => _instance;
  
  // Internal constructor
  ServiceLocator._internal();
  
  // Services
  late DatabaseService _databaseService;
  late DatabaseHelper _databaseHelper;
  
  // Repositories
  late ClassRepository _classRepository;
  late StudentRepository _studentRepository;
  late AttendanceRepository _attendanceRepository;
  
  // Providers
  late ThemeProvider _themeProvider;
  late AuthProvider _authProvider;
  late ClassProvider _classProvider;
  late StudentProvider _studentProvider;
  late AttendanceProvider _attendanceProvider;
  
  /// Initialize all services and dependencies
  Future<void> initialize() async {
    // Initialize services
    _databaseService = DatabaseService();
    await _databaseService.initDatabase();
    _databaseHelper = DatabaseHelper();
    
    // Initialize repositories
    _classRepository = ClassRepository();
    _studentRepository = StudentRepository();
    _attendanceRepository = AttendanceRepository();
    
    // Initialize providers
    _themeProvider = ThemeProvider();
    _authProvider = AuthProvider();
    _classProvider = ClassProvider();
    _studentProvider = StudentProvider();
    _attendanceProvider = AttendanceProvider();
  }
  
  /// Get all providers for MultiProvider
  List<SingleChildWidget> getProviders() {
    return [
      ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
      ChangeNotifierProvider<ClassProvider>.value(value: _classProvider),
      ChangeNotifierProvider<StudentProvider>.value(value: _studentProvider),
      ChangeNotifierProvider<AttendanceProvider>.value(value: _attendanceProvider),
    ];
  }
  
  /// Reset all providers
  void resetProviders() {
    _authProvider = AuthProvider();
    _classProvider = ClassProvider();
    _studentProvider = StudentProvider();
    _attendanceProvider = AttendanceProvider();
  }
  
  /// Close all services
  Future<void> dispose() async {
    await _databaseService.close();
  }
  
  // Getters for services and repositories
  DatabaseService get databaseService => _databaseService;
  DatabaseHelper get databaseHelper => _databaseHelper;
  ClassRepository get classRepository => _classRepository;
  StudentRepository get studentRepository => _studentRepository;
  AttendanceRepository get attendanceRepository => _attendanceRepository;
  ThemeProvider get themeProvider => _themeProvider;
  AuthProvider get authProvider => _authProvider;
  ClassProvider get classProvider => _classProvider;
  StudentProvider get studentProvider => _studentProvider;
  AttendanceProvider get attendanceProvider => _attendanceProvider;
}