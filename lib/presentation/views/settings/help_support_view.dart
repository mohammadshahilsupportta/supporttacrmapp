import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  static const String supportEmail = 'info@supporttasolutions.com';
  static const String supportPhone = '+918590377418';
  static const String supportWhatsApp = '+918590377418';

  Future<void> _launchEmail() async {
    try {
      final Uri emailUri = Uri.parse('mailto:$supportEmail?subject=Support Request');
      
      // Try to launch directly - canLaunchUrl sometimes returns false even when email app is available
      try {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // If launch fails, try checking first
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: Copy email to clipboard
          await Clipboard.setData(ClipboardData(text: supportEmail));
          if (Get.context != null && Get.context!.mounted) {
            Get.snackbar(
              'Email Copied',
              'Email address copied to clipboard: $supportEmail',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
        }
      }
    } catch (e) {
      // Final fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: supportEmail));
      if (Get.context != null && Get.context!.mounted) {
        Get.snackbar(
          'Email Copied',
          'Email address copied to clipboard: $supportEmail',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _launchPhone() async {
    try {
      final Uri phoneUri = Uri.parse('tel:$supportPhone');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (Get.context != null && Get.context!.mounted) {
          Get.snackbar(
            'Error',
            'Could not make phone call',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (Get.context != null && Get.context!.mounted) {
        Get.snackbar(
          'Error',
          'Could not make phone call',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    // Remove + and spaces for WhatsApp URL
    final cleanNumber = supportWhatsApp.replaceAll(RegExp(r'[+\s]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: try tel: scheme
      final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor.withOpacity(0.1),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        size: 32,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Contact our support team',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contact Options
            Text(
              'Contact Us',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Email
            _buildContactCard(
              context,
              icon: Icons.email,
              title: 'Email',
              subtitle: supportEmail,
              color: Colors.blue,
              onTap: _launchEmail,
            ),
            const SizedBox(height: 12),

            // Phone
            _buildContactCard(
              context,
              icon: Icons.phone,
              title: 'Phone',
              subtitle: supportPhone,
              color: Colors.green,
              onTap: _launchPhone,
            ),
            const SizedBox(height: 12),

            // WhatsApp
            _buildContactCard(
              context,
              icon: Icons.chat,
              title: 'WhatsApp',
              subtitle: supportWhatsApp,
              color: const Color(0xFF25D366), // WhatsApp green
              onTap: _launchWhatsApp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

