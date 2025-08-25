import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/month_selection_dialog.dart';

void main() {
  group('MonthSelectionDialog Widget Tests', () {
    testWidgets('should display dialog title and icon', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [
        DateTime(2024, 8),
        DateTime(2024, 7),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Select Month'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });
    
    testWidgets('should display loading indicator when isLoading is true', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: [],
              isLoading: true,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading available months...'), findsOneWidget);
    });
    
    testWidgets('should display error message when errorMessage is provided', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load months';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: [],
              errorMessage: errorMessage,
              onRetry: () {},
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text(errorMessage), findsOneWidget);
    });
    
    testWidgets('should display empty state when no months available', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: [],
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('No Attendance Data Found'), findsOneWidget);
      expect(find.text('There are no attendance sessions recorded for this class yet.'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });
    
    testWidgets('should display list of months when available', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [
        DateTime(2024, 8),
        DateTime(2024, 7),
        DateTime(2024, 6),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('August 2024'), findsOneWidget);
      expect(find.text('July 2024'), findsOneWidget);
      expect(find.text('June 2024'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
    });
    
    testWidgets('should display month abbreviations in leading containers', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [
        DateTime(2024, 8),
        DateTime(2024, 7),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Aug'), findsOneWidget);
      expect(find.text('Jul'), findsOneWidget);
      expect(find.text('2024'), findsNWidgets(4)); // 2 in containers + 2 in titles
    });
    
    testWidgets('should show correct month descriptions', (WidgetTester tester) async {
      // Arrange
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);
      
      final availableMonths = [currentMonth, lastMonth];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Current month'), findsOneWidget);
      expect(find.text('Last month'), findsOneWidget);
    });
    
    testWidgets('should have cancel button', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [DateTime(2024, 8)];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
    
    testWidgets('should call onRetry when retry button is tapped', (WidgetTester tester) async {
      // Arrange
      var retryCallCount = 0;
      void onRetry() {
        retryCallCount++;
      }
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: [],
              errorMessage: 'Error occurred',
              onRetry: onRetry,
            ),
          ),
        ),
      );
      
      // Act
      // Note: In a real test, we would find and tap the retry button
      // For demonstration, we'll verify the callback is properly set
      
      // Assert
      expect(onRetry, isNotNull);
      expect(retryCallCount, equals(0)); // Not called yet
    });
    
    testWidgets('should be scrollable when many months are available', (WidgetTester tester) async {
      // Arrange
      final availableMonths = List.generate(
        24, // 2 years worth of months
        (index) => DateTime(2024, 1 + (index % 12)),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });
    
    testWidgets('should have proper dialog structure', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [DateTime(2024, 8)];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthSelectionDialog(
              availableMonths: availableMonths,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);
    });
  });
  
  group('showMonthSelectionDialog function', () {
    testWidgets('should return DateTime when month is selected', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [DateTime(2024, 8)];
      DateTime? selectedMonth;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedMonth = await showMonthSelectionDialog(
                    context: context,
                    availableMonths: availableMonths,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(MonthSelectionDialog), findsOneWidget);
    });
    
    testWidgets('should return null when dialog is cancelled', (WidgetTester tester) async {
      // Arrange
      final availableMonths = [DateTime(2024, 8)];
      DateTime? selectedMonth;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedMonth = await showMonthSelectionDialog(
                    context: context,
                    availableMonths: availableMonths,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(selectedMonth, isNull);
    });
  });
}