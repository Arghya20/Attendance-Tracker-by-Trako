import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';
import 'package:attendance_tracker/services/cloud_sync_service.dart';
import 'package:intl/intl.dart';

class CloudSyncStatusCard extends StatefulWidget {
  const CloudSyncStatusCard({super.key});

  @override
  State<CloudSyncStatusCard> createState() => _CloudSyncStatusCardState();
}

class _CloudSyncStatusCardState extends State<CloudSyncStatusCard> {
  final CloudSyncService _cloudSyncService = CloudSyncService();
  bool _isLoading = false;
  Map<String, dynamic>? _cloudMetadata;

  @override
  void initState() {
    super.initState();
    _loadCloudMetadata();
  }

  Future<void> _loadCloudMetadata() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    try {
      final metadata = await _cloudSyncService.getCloudDataMetadata(
        authProvider.currentUser!,
      );
      if (mounted) {
        setState(() {
          _cloudMetadata = metadata;
        });
      }
    } catch (e) {
      debugPrint('Error loading cloud metadata: $e');
    }
  }

  Future<void> _syncNow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _cloudSyncService.syncToCloud(authProvider.currentUser!);
      await _loadCloudMetadata();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    
    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        // Handle Firestore Timestamp
        dateTime = DateTime.parse(timestamp.toString());
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else {
        return DateFormat('MMM d, y h:mm a').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final lastSync = _cloudSyncService.lastSyncTime;
    final isSyncing = _cloudSyncService.isSyncing || _isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cloud Sync',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Status',
              isSyncing ? 'Syncing...' : 'Active',
              isSyncing ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Last Sync',
              _formatTimestamp(lastSync),
              null,
            ),
            if (_cloudMetadata != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                'Cloud Data',
                '${_cloudMetadata!['metadata']['total_classes']} classes, '
                '${_cloudMetadata!['metadata']['total_students']} students',
                null,
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Sync Method',
              user.phoneNumber != null ? 'Phone Number' : 'Email',
              null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSyncing ? null : _syncNow,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your data is automatically synced every 5 minutes and when you log out. '
              'If you reinstall the app, your data will be restored automatically.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
