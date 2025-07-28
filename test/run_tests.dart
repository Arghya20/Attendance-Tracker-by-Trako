import 'package:flutter_test/flutter_test.dart';

// Import all unit test files
import 'unit/models/class_model_test.dart' as class_model_test;
import 'unit/models/student_model_test.dart' as student_model_test;
import 'unit/models/attendance_session_model_test.dart' as attendance_session_model_test;
import 'unit/models/attendance_record_model_test.dart' as attendance_record_model_test;
import 'unit/providers/theme_provider_test.dart' as theme_provider_test;
import 'unit/repositories/class_repository_test.dart' as class_repository_test;
import 'unit/services/database_service_test.dart' as database_service_test;

// Import all widget test files
import 'widget/loading_indicator_test.dart' as loading_indicator_test;
import 'widget/error_message_test.dart' as error_message_test;
import 'widget/action_button_test.dart' as action_button_test;
import 'widget/custom_snackbar_test.dart' as custom_snackbar_test;
import 'widget/animated_list_item_test.dart' as animated_list_item_test;

void main() {
  group('All Tests', () {
    // Run all unit test files
    group('Unit Tests', () {
      class_model_test.main();
      student_model_test.main();
      attendance_session_model_test.main();
      attendance_record_model_test.main();
      theme_provider_test.main();
      class_repository_test.main();
      database_service_test.main();
    });
    
    // Run all widget test files
    group('Widget Tests', () {
      loading_indicator_test.main();
      error_message_test.main();
      action_button_test.main();
      custom_snackbar_test.main();
      animated_list_item_test.main();
    });
  });
}