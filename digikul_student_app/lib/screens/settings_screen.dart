import 'package:flutter/material.dart';

// --- Theme Colors ---
const Color primaryColor = Color(0xFF5247eb);
const Color backgroundLight = Color(0xFFf6f6f8);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoDownloadEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedQuality = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: backgroundLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings Section
            _buildSectionHeader('App Settings'),
            _buildSettingsSection(),

            const SizedBox(height: 24),

            // Media Settings Section
            _buildSectionHeader('Media Settings'),
            _buildMediaSection(),

            const SizedBox(height: 24),

            // Account Settings Section
            _buildSectionHeader('Account'),
            _buildAccountSection(),

            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About'),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive notifications for new lectures and updates'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeThumbColor: primaryColor,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dark mode toggle coming soon!'),
                ),
              );
            },
            activeThumbColor: primaryColor,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Auto Download'),
            subtitle: const Text('Automatically download materials when on WiFi'),
            value: _autoDownloadEnabled,
            onChanged: (value) {
              setState(() {
                _autoDownloadEnabled = value;
              });
            },
            activeThumbColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageDialog,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Video Quality'),
            subtitle: Text(_selectedQuality),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showQualityDialog,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Storage'),
            subtitle: const Text('Manage downloaded content'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage management coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, color: primaryColor),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: primaryColor),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: primaryColor),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy policy coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: primaryColor),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of service coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline, color: primaryColor),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.feedback_outlined, color: primaryColor),
            title: const Text('Send Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback system coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star_outline, color: primaryColor),
            title: const Text('Rate App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('App rating coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.share_outlined, color: primaryColor),
            title: const Text('Share App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = <String>['English', 'Hindi', 'Bengali', 'Tamil', 'Telugu'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((language) {
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showQualityDialog() {
    final qualities = <String>['Low', 'Medium', 'High'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Quality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: qualities.map((quality) {
              return RadioListTile<String>(
                title: Text(quality),
                subtitle: Text(_getQualityDescription(quality)),
                value: quality,
                groupValue: _selectedQuality,
                onChanged: (value) {
                  setState(() {
                    _selectedQuality = value!;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getQualityDescription(String quality) {
    switch (quality) {
      case 'Low':
        return 'Best for slow connections';
      case 'Medium':
        return 'Balanced quality and bandwidth';
      case 'High':
        return 'Best quality (requires good connection)';
      default:
        return '';
    }
  }
}
