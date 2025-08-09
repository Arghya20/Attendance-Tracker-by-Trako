import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/utils/validation_utils.dart';
import 'package:attendance_tracker/utils/error_handler.dart';

class AddStudentDialog extends StatefulWidget {
  final int classId;
  final Student? studentToEdit;
  
  const AddStudentDialog({
    super.key,
    required this.classId,
    this.studentToEdit,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _animationController.forward();
    
    if (widget.studentToEdit != null) {
      _nameController.text = widget.studentToEdit!.name;
      if (widget.studentToEdit!.rollNumber != null) {
        _rollNumberController.text = widget.studentToEdit!.rollNumber!;
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.studentToEdit != null;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        title: Text(
          isEditMode ? 'Edit Student' : 'Add New Student',
          style: theme.textTheme.titleLarge,
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEditMode) ...[
                Text(
                  'Add a new student to this class',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  hintText: 'Enter student name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  filled: true,
                  errorMaxLines: 2,
                ),
                validator: (value) {
                  return ValidationUtils.validateLength(
                    value,
                    2,
                    50,
                    'Student name',
                  );
                },
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rollNumberController,
                decoration: InputDecoration(
                  labelText: 'Roll Number (Optional)',
                  hintText: 'Enter roll number',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  filled: true,
                ),
                validator: (value) {
                  return ValidationUtils.validateMaxLength(
                    value,
                    20,
                    'Roll number',
                  );
                },
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveStudent(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () {
              _animationController.reverse().then((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveStudent,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditMode ? theme.colorScheme.primary : theme.colorScheme.primary,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(isEditMode ? 'Save Changes' : 'Add Student'),
          ),
        ],
      ),
    );
  }
  
  void _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final rollNumber = _rollNumberController.text.trim().isNotEmpty 
        ? _rollNumberController.text.trim() 
        : null;
    
    try {
      bool success;
      
      if (widget.studentToEdit == null) {
        // Add new student
        success = await studentProvider.addStudent(widget.classId, name, rollNumber);
      } else {
        // Update existing student
        final updatedStudent = widget.studentToEdit!.copyWith(
          name: name,
          rollNumber: rollNumber,
        );
        success = await studentProvider.updateStudent(updatedStudent);
      }
      
      if (!mounted) return;
      
      if (success) {
        _animationController.reverse().then((_) {
          Navigator.pop(context);
          CustomSnackBar.show(
            context: context,
            message: widget.studentToEdit == null
                ? 'Student "$name" added successfully'
                : 'Student updated to "$name" successfully',
            type: SnackBarType.success,
          );
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = studentProvider.error ?? 'Failed to save student';
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      // Log the error
      ErrorHandler.logError('AddStudentDialog', e, stackTrace);
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }
}