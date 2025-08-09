import 'package:flutter_test/flutter_test.dart';

/// Test helper class for month filtering functionality
class MonthFilteringTestHelper {
  /// Extracts unique months from attendance records
  /// Returns months sorted in chronological order (most recent first)
  static List<DateTime> extractAvailableMonths(List<Map<String, dynamic>> attendanceRecords) {
    if (attendanceRecords.isEmpty) {
      return [];
    }
    
    try {
      // Extract unique months from attendance records
      final Set<DateTime> monthsSet = {};
      
      for (final record in attendanceRecords) {
        final dateStr = record['session_date'] as String?;
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          // Create a DateTime representing the first day of the month
          final monthDate = DateTime(date.year, date.month, 1);
          monthsSet.add(monthDate);
        }
      }
      
      // Convert to list and sort in chronological order (most recent first)
      final monthsList = monthsSet.toList();
      monthsList.sort((a, b) => b.compareTo(a)); // Descending order (most recent first)
      
      return monthsList;
    } catch (e) {
      return [];
    }
  }
  
  /// Filters attendance records by the selected month
  /// Returns all records if no month is selected (null)
  static List<Map<String, dynamic>> getFilteredAttendanceRecords(
    List<Map<String, dynamic>> attendanceRecords,
    DateTime? selectedMonth,
  ) {
    // If no month is selected, return all records
    if (selectedMonth == null) {
      return attendanceRecords;
    }
    
    try {
      return attendanceRecords.where((record) {
        final dateStr = record['session_date'] as String?;
        if (dateStr == null) return false;
        
        final recordDate = DateTime.parse(dateStr);
        // Check if the record's month and year match the selected month
        return recordDate.year == selectedMonth.year && 
               recordDate.month == selectedMonth.month;
      }).toList();
    } catch (e) {
      return attendanceRecords; // Return unfiltered records on error
    }
  }
  
  /// Calculates attendance statistics from filtered records
  static Map<String, dynamic> calculateAttendanceStats(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return {
        'percentage': 0.0,
        'presentCount': 0,
        'totalCount': 0,
      };
    }
    
    try {
      final presentCount = records.where((record) => record['is_present'] == 1).length;
      final totalCount = records.length;
      final percentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;
      
      return {
        'percentage': percentage,
        'presentCount': presentCount,
        'totalCount': totalCount,
      };
    } catch (e) {
      return {
        'percentage': 0.0,
        'presentCount': 0,
        'totalCount': 0,
      };
    }
  }
}

void main() {
  group('Month Filtering Functionality Tests', () {
    group('Month Extraction Logic', () {
      test('should extract unique months from attendance records', () {
        // Test data with records from different months
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-01-20', 'is_present': 0},
          {'session_date': '2024-02-10', 'is_present': 1},
          {'session_date': '2024-02-25', 'is_present': 1},
          {'session_date': '2024-03-05', 'is_present': 0},
        ];

        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths(attendanceRecords);

        expect(availableMonths.length, equals(3));
        expect(availableMonths[0], equals(DateTime(2024, 3, 1))); // Most recent first
        expect(availableMonths[1], equals(DateTime(2024, 2, 1)));
        expect(availableMonths[2], equals(DateTime(2024, 1, 1)));
      });

      test('should return empty list for empty attendance records', () {
        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths([]);

        expect(availableMonths, isEmpty);
      });

      test('should handle records with null session_date', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': null, 'is_present': 0},
          {'session_date': '2024-02-10', 'is_present': 1},
        ];

        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths(attendanceRecords);

        expect(availableMonths.length, equals(2));
        expect(availableMonths[0], equals(DateTime(2024, 2, 1)));
        expect(availableMonths[1], equals(DateTime(2024, 1, 1)));
      });

      test('should handle invalid date formats gracefully', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': 'invalid-date', 'is_present': 0},
          {'session_date': '2024-02-10', 'is_present': 1},
        ];

        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths(attendanceRecords);

        // Should return empty list due to error handling
        expect(availableMonths, isEmpty);
      });

      test('should sort months in descending order (most recent first)', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-03-10', 'is_present': 1},
          {'session_date': '2024-02-20', 'is_present': 0},
        ];

        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths(attendanceRecords);

        expect(availableMonths.length, equals(3));
        expect(availableMonths[0], equals(DateTime(2024, 3, 1)));
        expect(availableMonths[1], equals(DateTime(2024, 2, 1)));
        expect(availableMonths[2], equals(DateTime(2024, 1, 1)));
      });

      test('should handle duplicate months correctly', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-01-20', 'is_present': 0},
          {'session_date': '2024-01-25', 'is_present': 1},
          {'session_date': '2024-02-10', 'is_present': 1},
        ];

        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths(attendanceRecords);

        expect(availableMonths.length, equals(2));
        expect(availableMonths[0], equals(DateTime(2024, 2, 1)));
        expect(availableMonths[1], equals(DateTime(2024, 1, 1)));
      });
    });

    group('Record Filtering Logic', () {
      test('should filter records by selected month', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-01-20', 'is_present': 0},
          {'session_date': '2024-02-10', 'is_present': 1},
          {'session_date': '2024-02-25', 'is_present': 1},
          {'session_date': '2024-03-05', 'is_present': 0},
        ];

        final selectedMonth = DateTime(2024, 2, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );

        expect(filteredRecords.length, equals(2));
        expect(filteredRecords[0]['session_date'], equals('2024-02-10'));
        expect(filteredRecords[1]['session_date'], equals('2024-02-25'));
      });

      test('should return all records when no month is selected', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-02-10', 'is_present': 1},
          {'session_date': '2024-03-05', 'is_present': 0},
        ];

        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          null,
        );

        expect(filteredRecords.length, equals(3));
        expect(filteredRecords, equals(attendanceRecords));
      });

      test('should return empty list when no records match selected month', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-02-10', 'is_present': 1},
        ];

        final selectedMonth = DateTime(2024, 3, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );

        expect(filteredRecords, isEmpty);
      });

      test('should handle records with null session_date', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': null, 'is_present': 0},
          {'session_date': '2024-01-20', 'is_present': 1},
        ];

        final selectedMonth = DateTime(2024, 1, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );

        expect(filteredRecords.length, equals(2));
        expect(filteredRecords[0]['session_date'], equals('2024-01-15'));
        expect(filteredRecords[1]['session_date'], equals('2024-01-20'));
      });

      test('should handle invalid date formats gracefully', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': 'invalid-date', 'is_present': 0},
          {'session_date': '2024-01-20', 'is_present': 1},
        ];

        final selectedMonth = DateTime(2024, 1, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );

        // Should return original records due to error handling
        expect(filteredRecords, equals(attendanceRecords));
      });

      test('should filter across different years correctly', () {
        final attendanceRecords = [
          {'session_date': '2023-12-15', 'is_present': 1},
          {'session_date': '2024-01-15', 'is_present': 0},
          {'session_date': '2024-12-15', 'is_present': 1},
        ];

        final selectedMonth = DateTime(2024, 12, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );

        expect(filteredRecords.length, equals(1));
        expect(filteredRecords[0]['session_date'], equals('2024-12-15'));
      });
    });

    group('Statistics Calculation', () {
      test('should calculate correct attendance percentage', () {
        final records = [
          {'is_present': 1},
          {'is_present': 1},
          {'is_present': 0},
          {'is_present': 1},
        ];

        final stats = MonthFilteringTestHelper.calculateAttendanceStats(records);

        expect(stats['percentage'], equals(75.0));
        expect(stats['presentCount'], equals(3));
        expect(stats['totalCount'], equals(4));
      });

      test('should handle empty records list', () {
        final stats = MonthFilteringTestHelper.calculateAttendanceStats([]);

        expect(stats['percentage'], equals(0.0));
        expect(stats['presentCount'], equals(0));
        expect(stats['totalCount'], equals(0));
      });

      test('should handle all present records', () {
        final records = [
          {'is_present': 1},
          {'is_present': 1},
          {'is_present': 1},
        ];

        final stats = MonthFilteringTestHelper.calculateAttendanceStats(records);

        expect(stats['percentage'], equals(100.0));
        expect(stats['presentCount'], equals(3));
        expect(stats['totalCount'], equals(3));
      });

      test('should handle all absent records', () {
        final records = [
          {'is_present': 0},
          {'is_present': 0},
          {'is_present': 0},
        ];

        final stats = MonthFilteringTestHelper.calculateAttendanceStats(records);

        expect(stats['percentage'], equals(0.0));
        expect(stats['presentCount'], equals(0));
        expect(stats['totalCount'], equals(3));
      });

      test('should handle single record correctly', () {
        final records = [
          {'is_present': 1},
        ];

        final stats = MonthFilteringTestHelper.calculateAttendanceStats(records);

        expect(stats['percentage'], equals(100.0));
        expect(stats['presentCount'], equals(1));
        expect(stats['totalCount'], equals(1));
      });

      test('should handle malformed records gracefully', () {
        final records = [
          {'is_present': 1},
          {'invalid_field': 'value'}, // This record doesn't have 'is_present' field
          {'is_present': 0},
        ];

        final stats = MonthFilteringTestHelper.calculateAttendanceStats(records);

        // Should handle malformed records by treating missing 'is_present' as 0 (absent)
        // So we have: 1 present, 0 present (missing treated as 0), 0 present = 1/3 = 33.33%
        expect(stats['percentage'], closeTo(33.33, 0.01));
        expect(stats['presentCount'], equals(1));
        expect(stats['totalCount'], equals(3));
      });

      test('should calculate percentage with decimal precision', () {
        final records = [
          {'is_present': 1},
          {'is_present': 0},
          {'is_present': 1},
        ];

        final stats = MonthFilteringTestHelper.calculateAttendanceStats(records);

        expect(stats['percentage'], closeTo(66.67, 0.01));
        expect(stats['presentCount'], equals(2));
        expect(stats['totalCount'], equals(3));
      });
    });

    group('Integration Tests', () {
      test('should work correctly with complete filtering workflow', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-01-20', 'is_present': 0},
          {'session_date': '2024-02-10', 'is_present': 1},
          {'session_date': '2024-02-25', 'is_present': 1},
          {'session_date': '2024-03-05', 'is_present': 0},
        ];

        // Step 1: Extract available months
        final availableMonths = MonthFilteringTestHelper.extractAvailableMonths(attendanceRecords);
        expect(availableMonths.length, equals(3));

        // Step 2: Filter by February 2024
        final selectedMonth = DateTime(2024, 2, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );
        expect(filteredRecords.length, equals(2));

        // Step 3: Calculate statistics for filtered records
        final stats = MonthFilteringTestHelper.calculateAttendanceStats(filteredRecords);
        expect(stats['percentage'], equals(100.0)); // Both February records are present
        expect(stats['presentCount'], equals(2));
        expect(stats['totalCount'], equals(2));
      });

      test('should handle edge case with no matching records', () {
        final attendanceRecords = [
          {'session_date': '2024-01-15', 'is_present': 1},
          {'session_date': '2024-02-10', 'is_present': 1},
        ];

        // Filter by March 2024 (no records)
        final selectedMonth = DateTime(2024, 3, 1);
        final filteredRecords = MonthFilteringTestHelper.getFilteredAttendanceRecords(
          attendanceRecords,
          selectedMonth,
        );
        expect(filteredRecords, isEmpty);

        // Calculate statistics for empty filtered records
        final stats = MonthFilteringTestHelper.calculateAttendanceStats(filteredRecords);
        expect(stats['percentage'], equals(0.0));
        expect(stats['presentCount'], equals(0));
        expect(stats['totalCount'], equals(0));
      });
    });
  });
}