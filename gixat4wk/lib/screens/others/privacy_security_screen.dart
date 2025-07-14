import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Privacy & Security',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy Matters',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We are committed to protecting your personal information and ensuring transparency in how we handle your data.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Policy Section
            _buildSection(
              context,
              'Privacy Policy',
              'Learn how we collect, use, and protect your personal information.',
              Icons.policy_outlined,
              () => _showPrivacyPolicy(context),
            ),

            const SizedBox(height: 16),

            // Terms of Service Section
            _buildSection(
              context,
              'Terms of Service',
              'Read our terms and conditions for using the Gixat service.',
              Icons.description_outlined,
              () => _showTermsOfService(context),
            ),

            const SizedBox(height: 16),

            // Data Management Section
            _buildSection(
              context,
              'Data Management',
              'Manage your personal data and privacy preferences.',
              Icons.data_usage_outlined,
              () => _showDataManagement(context),
            ),

            const SizedBox(height: 16),

            // Security Settings Section
            _buildSection(
              context,
              'Security Settings',
              'Configure your account security and authentication options.',
              Icons.lock_outlined,
              () => _showSecuritySettings(context),
            ),

            const SizedBox(height: 24),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Questions or Concerns?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you have any questions about our privacy practices or need help with your account, please contact us.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchEmail(),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchWebsite(),
                          icon: const Icon(Icons.web_outlined),
                          label: const Text('Visit Website'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Version
            Center(
              child: Text(
                'Gixat App v1.0.0\nLast updated: ${_getLastUpdatedDate()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.outline,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPolicySheet(
        context,
        'Privacy Policy',
        _getPrivacyPolicyContent(),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPolicySheet(
        context,
        'Terms of Service',
        _getTermsOfServiceContent(),
      ),
    );
  }

  void _showDataManagement(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Data Management'),
        content: const Text(
          'Your data management options:\n\n'
          '• Export your data\n'
          '• Delete your account\n'
          '• Manage privacy preferences\n'
          '• View data usage\n\n'
          'These features are available in your profile settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.back(); // Go back to profile screen
            },
            child: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Security Settings'),
        content: const Text(
          'Security features:\n\n'
          '• Two-factor authentication\n'
          '• Password management\n'
          '• Login activity monitoring\n'
          '• Device management\n\n'
          'These features will be available in future updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySheet(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
          ),
          
          // Bottom padding
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getPrivacyPolicyContent() {
    return '''
PRIVACY POLICY

Last updated: ${_getLastUpdatedDate()}

1. INFORMATION WE COLLECT
We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support.

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
• Provide, maintain, and improve our services
• Process transactions and send related information
• Send technical notices and support messages
• Respond to your comments and questions

3. INFORMATION SHARING
We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.

4. DATA SECURITY
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. YOUR RIGHTS
You have the right to:
• Access your personal information
• Correct inaccurate information
• Delete your account and personal information
• Export your data

6. CONTACT US
If you have any questions about this Privacy Policy, please contact us at:
Email: privacy@gixat.com
Website: https://gixat.com/privacy

This policy may be updated from time to time. We will notify you of any significant changes.
''';
  }

  String _getTermsOfServiceContent() {
    return '''
TERMS OF SERVICE

Last updated: ${_getLastUpdatedDate()}

1. ACCEPTANCE OF TERMS
By accessing and using Gixat, you accept and agree to be bound by the terms and provision of this agreement.

2. DESCRIPTION OF SERVICE
Gixat is a vehicle service management platform that allows users to manage automotive service requests, track vehicle maintenance, and communicate with service providers.

3. USER OBLIGATIONS
You agree to:
• Provide accurate and complete information
• Use the service only for lawful purposes
• Respect the rights of other users
• Comply with all applicable laws and regulations

4. PROHIBITED USES
You may not use our service:
• For any unlawful purpose or to solicit unlawful activity
• To transmit any harmful or malicious content
• To interfere with or disrupt the service
• To violate any applicable laws or regulations

5. INTELLECTUAL PROPERTY
The service and its original content, features, and functionality are owned by Gixat and are protected by intellectual property laws.

6. LIMITATION OF LIABILITY
Gixat shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.

7. TERMINATION
We may terminate or suspend your account and access to the service immediately, without prior notice, for any reason.

8. GOVERNING LAW
These terms shall be governed by and construed in accordance with the laws of [Jurisdiction].

9. CONTACT INFORMATION
For questions about these Terms of Service, please contact us at:
Email: legal@gixat.com
Website: https://gixat.com/terms
''';
  }

  String _getLastUpdatedDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@gixat.com',
      query: 'subject=Privacy and Security Inquiry',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Get.snackbar(
        'Error',
        'Could not open email client',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://gixat.com');
    
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Could not open website',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}