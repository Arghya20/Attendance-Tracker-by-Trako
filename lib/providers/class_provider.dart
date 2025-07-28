import 'package:flutter/foundation.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/repositories/class_repository.dart';

class ClassProvider extends ChangeNotifier {
  final ClassRepository _repository = ClassRepository();
  
  List<Class> _classes = [];
  Class? _selectedClass;
  bool _isLoading = false;
  String? _error;
  
  // Cache for class details
  final Map<int, Class> _classCache = {};
  DateTime? _lastLoadTime;
  
  // Getters
  List<Class> get classes => _classes;
  Class? get selectedClass => _selectedClass;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load all classes
  Future<void> loadClasses() async {
    // Check if we have recently loaded classes (within the last 30 seconds)
    final now = DateTime.now();
    if (_lastLoadTime != null && 
        now.difference(_lastLoadTime!).inSeconds < 30 && 
        _classes.isNotEmpty) {
      // Use cached data
      return;
    }
    
    _setLoading(true);
    try {
      _classes = await _repository.getAllClasses();
      
      // Update cache
      for (final classItem in _classes) {
        if (classItem.id != null) {
          _classCache[classItem.id!] = classItem;
        }
      }
      
      _lastLoadTime = now;
      _error = null;
    } catch (e) {
      _error = 'Failed to load classes: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Force reload classes (bypasses cache)
  Future<void> forceLoadClasses() async {
    _lastLoadTime = null; // Clear cache timestamp
    await loadClasses();
  }
  
  // Select a class
  Future<void> selectClass(int classId) async {
    // Check if we have this class in cache
    if (_classCache.containsKey(classId)) {
      _selectedClass = _classCache[classId];
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    try {
      _selectedClass = await _repository.getClassById(classId);
      
      // Update cache
      if (_selectedClass != null && _selectedClass!.id != null) {
        _classCache[_selectedClass!.id!] = _selectedClass!;
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load class details: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Create a new class
  Future<bool> addClass(String name) async {
    _setLoading(true);
    try {
      final newClass = await _repository.createClass(name);
      if (newClass != null) {
        _classes.add(newClass);
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to create class';
      return false;
    } catch (e) {
      _error = 'Failed to create class: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update a class
  Future<bool> updateClass(Class classModel) async {
    _setLoading(true);
    try {
      final success = await _repository.updateClass(classModel);
      if (success) {
        final index = _classes.indexWhere((c) => c.id == classModel.id);
        if (index != -1) {
          _classes[index] = classModel;
        }
        if (_selectedClass?.id == classModel.id) {
          _selectedClass = classModel;
        }
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to update class';
      return false;
    } catch (e) {
      _error = 'Failed to update class: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a class
  Future<bool> deleteClass(int classId) async {
    _setLoading(true);
    try {
      final success = await _repository.deleteClass(classId);
      if (success) {
        _classes.removeWhere((c) => c.id == classId);
        if (_selectedClass?.id == classId) {
          _selectedClass = null;
        }
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to delete class';
      return false;
    } catch (e) {
      _error = 'Failed to delete class: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Pin operations
  Future<bool> pinClass(int classId) async {
    _setLoading(true);
    try {
      final success = await _repository.pinClass(classId);
      if (success) {
        // Force reload classes to get updated pin status and sorting
        await forceLoadClasses();
        _error = null;
        return true;
      }
      _error = 'Failed to pin class';
      return false;
    } catch (e) {
      _error = 'Failed to pin class: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> unpinClass(int classId) async {
    _setLoading(true);
    try {
      final success = await _repository.unpinClass(classId);
      if (success) {
        // Force reload classes to get updated pin status and sorting
        await forceLoadClasses();
        _error = null;
        return true;
      }
      _error = 'Failed to unpin class';
      return false;
    } catch (e) {
      _error = 'Failed to unpin class: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> togglePinStatus(int classId) async {
    _setLoading(true);
    try {
      final success = await _repository.togglePinStatus(classId);
      if (success) {
        // Force reload classes to get updated pin status and sorting
        await forceLoadClasses();
        _error = null;
        return true;
      }
      _error = 'Failed to toggle pin status';
      return false;
    } catch (e) {
      _error = 'Failed to toggle pin status: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear cache
  void clearCache() {
    _classCache.clear();
    _lastLoadTime = null;
  }
}