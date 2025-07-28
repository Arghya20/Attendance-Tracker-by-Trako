import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
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
              themeProvider.setThemeMode(selection.first);
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
      onTap: () => themeProvider.setColorScheme(index),
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
}