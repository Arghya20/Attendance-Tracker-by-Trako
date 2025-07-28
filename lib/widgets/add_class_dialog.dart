import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/utils/validation_utils.dart';
import 'package:attendance_tracker/utils/error_handler.dart';

class AddClassDialog extends StatefulWidget {
  final Class? classToEdit;
  
  const AddClassDialog({
    super.key,
    this.classToEdit,
  });

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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
    
    if (widget.classToEdit != null) {
      _nameController.text = widget.classToEdit!.name;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.classToEdit != null;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        title: Text(
          isEditMode ? 'Edit Class' : 'Add New Class',
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
                  'Create a new class or subject for tracking attendance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'Enter class or subject name',
                  prefixIcon: const Icon(Icons.school),
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
                    'Class name',
                  );
                },
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveClass(),
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
            onPressed: _isLoading ? null : _saveClass,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
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
                : Text(isEditMode ? 'Save Changes' : 'Add'),
          ),
        ],
      ),
    );
  }
  
  void _saveClass() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final name = _nameController.text.trim();
    
    try {
      bool success;
      
      if (widget.classToEdit == null) {
        // Add new class
        success = await classProvider.addClass(name);
      } else {
        // Update existing class
        final updatedClass = widget.classToEdit!.copyWith(name: name);
        success = await classProvider.updateClass(updatedClass);
      }
      
      if (!mounted) return;
      
      if (success) {
        _animationController.reverse().then((_) {
          Navigator.pop(context);
          CustomSnackBar.show(
            context: context,
            message: widget.classToEdit == null
                ? 'Class "$name" added successfully'
                : 'Class updated to "$name" successfully',
            type: SnackBarType.success,
          );
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = classProvider.error ?? 'Failed to save class';
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      // Log the error
      ErrorHandler.logError('AddClassDialog', e, stackTrace);
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }
}