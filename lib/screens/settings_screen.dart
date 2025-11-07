import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/widgets/backup_restore_dialog.dart';
import 'package:attendance_tracker/widgets/link_phone_dialog.dart';
import 'package:attendance_tracker/screens/auth/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'Unknown';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // User Profile Section
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return _buildUserProfileSection(authProvider);
            },
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Appearance',
            children: [
              _buildThemeModeSelector(themeProvider),
              const SizedBox(height: 16),
              _buildColorSchemeSelector(themeProvider),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Data Management',
            children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Export or import your attendance data'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showBackupRestoreDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: Text(_isLoading ? 'Loading...' : _appVersion),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Developer'),
                subtitle: const Text('Arghya Ghosh'),
                onTap: () {
                  CustomSnackBar.show(
                    context: context,
                    message: 'Developed By Arghya',
                    type: SnackBarType.info,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeModeSelector(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode),
              label: Text('Dark'),
            ),
          ],
          selected: {themeProvider.themeMode},
          onSelectionChanged: (Set<ThemeMode> selection) {
            if (selection.isNotEmpty) {
              _changeThemeMode(selection.first, themeProvider);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildColorSchemeSelector(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Scheme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            ThemeProvider.colorSchemeNames.length,
            (index) => _buildColorSchemeOption(
              index,
              ThemeProvider.colorSchemeNames[index],
              themeProvider,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildColorSchemeOption(
    int index,
    String name,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.colorSchemeIndex == index;
    
    return InkWell(
      onTap: () => _changeColorScheme(index, themeProvider),
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeColorScheme(int index, ThemeProvider themeProvider) async {
    try {
      await themeProvider.setColorScheme(index);
      
      // Ensure the current screen rebuilds
      if (mounted) {
        setState(() {});
        
        // Show visual feedback
        CustomSnackBar.show(
          context: context,
          message: 'Color scheme changed to ${ThemeProvider.colorSchemeNames[index]}',
          type: SnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to change color scheme',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _changeThemeMode(ThemeMode mode, ThemeProvider themeProvider) async {
    try {
      await themeProvider.setThemeMode(mode);
      
      // Ensure the current screen rebuilds
      if (mounted) {
        setState(() {});
        
        // Show visual feedback
        String modeName = mode.name;
        modeName = modeName[0].toUpperCase() + modeName.substring(1);
        
        CustomSnackBar.show(
          context: context,
          message: 'Theme mode changed to $modeName',
          type: SnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to change theme mode',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _showBackupRestoreDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const BackupRestoreDialog(),
    );
    
    // If data was restored, show a message and potentially refresh the app
    if (result == true && mounted) {
      CustomSnackBar.show(
        context: context,
        message: 'Data restored successfully. Please restart the app to see changes.',
        type: SnackBarType.info,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _buildUserProfileSection(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // User Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: user.photoURL == null
                        ? Text(
                            _getUserInitials(user),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.email!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                        if (user.phoneNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sign-in Methods
            Text(
              'Sign-in Methods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Phone Number
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone),
              title: const Text('Phone Number'),
              subtitle: Text(
                authProvider.hasPhoneProvider()
                    ? user.phoneNumber ?? 'Linked'
                    : 'Not linked',
              ),
              trailing: authProvider.hasPhoneProvider()
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _unlinkProvider('phone', authProvider),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: _linkPhoneNumber,
                    ),
            ),
            
            // Google Account
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login),
              title: const Text('Google Account'),
              subtitle: Text(
                authProvider.hasGoogleProvider()
                    ? user.email ?? 'Linked'
                    : 'Not linked',
              ),
              trailing: authProvider.hasGoogleProvider()
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _unlinkProvider('google.com', authProvider),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () => _linkGoogleAccount(authProvider),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Account Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getUserInitials(user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    } else if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      return 'U';
    }
    return 'U';
  }

  Future<void> _linkPhoneNumber() async {
    showDialog(
      context: context,
      builder: (context) => const LinkPhoneDialog(),
    );
  }

  Future<void> _linkGoogleAccount(AuthProvider authProvider) async {
    try {
      await authProvider.signInWithGoogle();
      CustomSnackBar.show(
        context: context,
        message: 'Google account linked successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      CustomSnackBar.show(
        context: context,
        message: 'Failed to link Google account: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _unlinkProvider(String provider, AuthProvider authProvider) async {
    final providers = authProvider.getUserProviders();

    if (providers.length <= 1) {
      CustomSnackBar.show(
        context: context,
        message: 'Cannot unlink the only sign-in method. Please add another method first.',
        type: SnackBarType.error,
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Unlink ${provider == 'phone' ? 'Phone Number' : 'Google Account'}',
      'Are you sure you want to unlink this sign-in method?',
    );

    if (confirmed) {
      try {
        if (provider == 'phone') {
          await authProvider.unlinkPhoneNumber();
        } else if (provider == 'google.com') {
          await authProvider.unlinkGoogleAccount();
        }
        
        CustomSnackBar.show(
          context: context,
          message: 'Sign-in method unlinked successfully',
          type: SnackBarType.success,
        );
      } catch (e) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to unlink: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
      'Sign Out',
      'Are you sure you want to sign out?',
    );

    if (confirmed) {
      try {
        await context.read<AuthProvider>().signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to sign out: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmDialog(
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone.',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await context.read<AuthProvider>().deleteAccount();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to delete account: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String content, {
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }
}