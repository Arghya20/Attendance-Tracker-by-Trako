import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/services/backup_service.dart';
import 'package:attendance_tracker/services/native_file_picker.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key});

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  Map<String, int>? _currentStats;

  @override
  void initState() {
    super.initState();
    _loadCurrentStats();
  }

  Future<void> _loadCurrentStats() async {
    try {
      final stats = await _backupService.getDatabaseStats();
      if (mounted) {
        setState(() {
          _currentStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.backup,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Backup & Restore',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStats != null) ...[
                        _buildCurrentDataSection(),
                        const SizedBox(height: 24),
                      ],
                      
                      _buildBackupSection(),
                      const SizedBox(height: 16),
                      _buildRestoreSection(),
                      
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStatRow('Classes', _currentStats!['classes']!),
            _buildStatRow('Students', _currentStats!['students']!),
            _buildStatRow('Sessions', _currentStats!['sessions']!),
            _buildStatRow('Records', _currentStats!['records']!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Backup',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Export all your data to a backup file that you can save and restore later.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _createBackup,
            icon: const Icon(Icons.download),
            label: const Text('Create & Download Backup'),
          ),
        ),
      ],
    );
  }

  Widget _buildRestoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restore Backup',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Paste your backup data to restore all classes, students, and attendance records.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickAndRestoreFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Backup File'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _showRestoreDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Paste Backup Text'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showRestoreInstructions,
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'How to restore',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _backupService.exportBackup();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        await _showBackupSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        CustomSnackBar.show(
          context: context,
          message: 'Failed to create backup: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _showBackupSuccessDialog(Map<String, dynamic> result) async {
    final fileName = result['fileName'] as String;
    final savedPath = result['savedPath'] as String?;
    final tempPath = result['tempPath'] as String;
    final fileSize = result['fileSize'] as int;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Backup Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: savedPath != null 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    savedPath != null ? Icons.download_done : Icons.share,
                    color: savedPath != null 
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          savedPath != null ? 'Saved to Downloads' : 'Ready to Share',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: savedPath != null 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          savedPath != null 
                              ? 'File saved to Downloads/Attendance Tracker folder'
                              : 'Use Share to save to Downloads or cloud storage',
                          style: TextStyle(
                            fontSize: 12,
                            color: savedPath != null 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('File: $fileName'),
            Text('Size: ${(fileSize / 1024).toStringAsFixed(1)} KB'),
            if (savedPath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Downloads/Attendance Tracker/$fileName',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              savedPath != null 
                  ? 'Your backup has been saved to the Downloads/Attendance Tracker folder. You can also share it to other locations if needed.'
                  : 'Tap Share below to save your backup to Downloads folder, email it to yourself, or save to cloud storage.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (savedPath != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close backup dialog too
              },
              child: const Text('Done'),
            ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _backupService.shareBackup(tempPath, fileName);
            },
            icon: const Icon(Icons.share),
            label: Text(savedPath != null ? 'Share Also' : 'Share & Save'),
          ),
          if (savedPath == null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Future<void> _showRestoreDialog() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your backup JSON content below:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste backup JSON here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will replace ALL current data!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                CustomSnackBar.show(
                  context: context,
                  message: 'Please paste backup content',
                  type: SnackBarType.error,
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
    
    if (result == true && controller.text.trim().isNotEmpty) {
      await _performRestore(controller.text.trim());
    }
  }

  Future<void> _performRestore(String backupContent) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse the JSON content
      final Map<String, dynamic> backup = 
          Map<String, dynamic>.from(jsonDecode(backupContent));
      
      // Restore the backup
      await _backupService.restoreFromBackup(backup);
      
      if (mounted) {
        await _showRestoreSuccessDialog();
        Navigator.of(context).pop(true); // Return true to indicate data changed
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to restore backup: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndRestoreFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? filePath;
      String? fileContent;

      // Try native file picker first
      if (Platform.isAndroid || Platform.isIOS) {
        filePath = await NativeFilePicker.pickJsonFile();
        if (filePath != null) {
          fileContent = await NativeFilePicker.readFileContent(filePath);
        }
      }

      if (fileContent == null) {
        // Fallback to text input if file picker fails or user cancels
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          await _showRestoreDialog();
          return;
        }
      }

      if (fileContent != null && fileContent.isNotEmpty) {
        // Show confirmation dialog with file details
        final shouldRestore = await _showFileRestoreConfirmation(filePath ?? 'Selected file');
        if (shouldRestore) {
          await _performRestore(fileContent);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to pick file: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showFileRestoreConfirmation(String fileName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${fileName.split('/').last}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will replace ALL current data!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showRestoreSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOutBack,
        )),
        child: FadeTransition(
          opacity: ModalRoute.of(context)!.animation!,
          child: _RestoreSuccessDialog(),
        ),
      ),
    );
  }

  Future<void> _showRestoreInstructions() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Restore'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Two ways to restore your data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '1. Select Backup File:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Tap "Select Backup File"'),
              Text('• Choose your backup JSON file'),
              Text('• Confirm to restore'),
              SizedBox(height: 12),
              Text(
                '2. Paste Backup Text:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Open backup file in text editor'),
              Text('• Copy all JSON content'),
              Text('• Tap "Paste Backup Text"'),
              Text('• Paste content and restore'),
              SizedBox(height: 12),
              Text(
                'Note: Both methods will replace ALL current data. Restart the app after restoring.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _RestoreSuccessDialog extends StatefulWidget {
  @override
  State<_RestoreSuccessDialog> createState() => _RestoreSuccessDialogState();
}

class _RestoreSuccessDialogState extends State<_RestoreSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _checkController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated success icon
            AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value * (1.0 + _pulseAnimation.value * 0.1),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CheckmarkPainter(
                            progress: _checkAnimation.value,
                            color: theme.colorScheme.onPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Success title
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Text(
                    'Restore Successful!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Success message
            AnimatedBuilder(
              animation: _checkAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _checkAnimation.value,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your backup has been successfully restored. All data has been updated.',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restart_alt,
                              color: theme.colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please restart the app to see all changes take effect.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            AnimatedBuilder(
              animation: _checkAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _checkAnimation.value,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Continue'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Close all dialogs and return to main screen
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final checkmarkSize = size.width * 0.4;
    
    // Define checkmark path
    final path = Path();
    path.moveTo(center.dx - checkmarkSize * 0.5, center.dy);
    path.lineTo(center.dx - checkmarkSize * 0.1, center.dy + checkmarkSize * 0.3);
    path.lineTo(center.dx + checkmarkSize * 0.5, center.dy - checkmarkSize * 0.3);

    // Create path metric to animate drawing
    final pathMetric = path.computeMetrics().first;
    final animatedPath = pathMetric.extractPath(0, pathMetric.length * progress);
    
    canvas.drawPath(animatedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _CheckmarkPainter && oldDelegate.progress != progress;
  }
}