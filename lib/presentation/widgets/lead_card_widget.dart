import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/lead_controller.dart';
import '../controllers/staff_controller.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/lead_model.dart';
import '../../data/models/category_model.dart';

class LeadCardWidget extends StatelessWidget {
  final LeadWithRelationsModel lead;
  final VoidCallback? onTap;
  final bool isReadOnly; // Make status and assigned to read-only
  final bool canEditStatus; // Allow editing status (overrides isReadOnly for status)
  final bool canEditAssignedTo; // Allow editing assigned to (overrides isReadOnly for assigned to)

  const LeadCardWidget({
    super.key, 
    required this.lead, 
    this.onTap,
    this.isReadOnly = false, // Default to false
    this.canEditStatus = true, // Default to true (can edit status)
    this.canEditAssignedTo = true, // Default to true (can edit assigned to)
  });

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.willContact:
        return Colors.blue.shade600;
      case LeadStatus.needFollowUp:
        return Colors.blue.shade500;
      case LeadStatus.appointmentScheduled:
        return Colors.yellow.shade700;
      case LeadStatus.proposalSent:
        return Colors.green.shade600;
      case LeadStatus.alreadyHas:
        return Colors.purple.shade600;
      case LeadStatus.noNeedNow:
        return Colors.orange.shade600;
      case LeadStatus.closedWon:
        return Colors.green.shade800;
      case LeadStatus.closedLost:
        return Colors.red.shade600;
    }
  }

  IconData _getStatusIcon(LeadStatus status) {
    switch (status) {
      case LeadStatus.willContact:
        return Icons.phone_in_talk;
      case LeadStatus.needFollowUp:
        return Icons.schedule;
      case LeadStatus.appointmentScheduled:
        return Icons.event;
      case LeadStatus.proposalSent:
        return Icons.description;
      case LeadStatus.alreadyHas:
        return Icons.check_box;
      case LeadStatus.noNeedNow:
        return Icons.watch_later;
      case LeadStatus.closedWon:
        return Icons.check_circle;
      case LeadStatus.closedLost:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.willContact:
        return 'Will Contact';
      case LeadStatus.needFollowUp:
        return 'Need Follow-Up';
      case LeadStatus.appointmentScheduled:
        return 'Appointment Scheduled';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.alreadyHas:
        return 'Already Has';
      case LeadStatus.noNeedNow:
        return 'No Need Now';
      case LeadStatus.closedWon:
        return 'Closed – Won';
      case LeadStatus.closedLost:
        return 'Closed – Lost';
    }
  }

  Color _getScoreColor(int score, String? category) {
    if (category != null) {
      switch (category.toLowerCase()) {
        case 'hot':
          return Colors.red;
        case 'warm':
          return Colors.orange;
        case 'cold':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }
    // Fallback based on score
    if (score >= 75) return Colors.red;
    if (score >= 50) return Colors.orange;
    if (score >= 25) return Colors.blue;
    return Colors.grey;
  }

  IconData _getScoreIcon(String? category) {
    if (category != null) {
      switch (category.toLowerCase()) {
        case 'hot':
          return Icons.local_fire_department;
        case 'warm':
          return Icons.wb_sunny;
        case 'cold':
          return Icons.ac_unit;
        default:
          return Icons.star;
      }
    }
    return Icons.star;
  }

  Future<void> _launchPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not make phone call',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(lead.status);
    final leadController = Get.find<LeadController>();
    final staffController = Get.find<StaffController>();
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, and Action Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        () {
                          final name = Helpers.safeDisplayString(lead.name);
                          return name.isNotEmpty ? name[0].toUpperCase() : 'L';
                        }(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Helpers.safeDisplayString(lead.name),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(lead.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons: Call and WhatsApp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lead.phone != null)
                        IconButton(
                          icon: const Icon(Icons.phone, size: 20),
                          color: theme.colorScheme.primary,
                          tooltip: 'Call ${lead.phone}',
                          onPressed: () => _launchPhone(lead.phone!),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (lead.whatsapp != null && lead.whatsapp!.isNotEmpty)
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                          color: const Color(0xFF25D366), // WhatsApp green
                          tooltip: 'WhatsApp ${lead.whatsapp}',
                          onPressed: () => _launchWhatsApp(lead.whatsapp!),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status and Assigned To in single row with headings
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headings
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Status',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Assigned To',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusDropdown(lead, leadController, statusColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAssignedToDropdown(context, lead, leadController, staffController),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Score Badge (if available)
              if (lead.score != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(lead.score!, lead.scoreCategory).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getScoreColor(lead.score!, lead.scoreCategory).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getScoreIcon(lead.scoreCategory),
                            size: 12,
                            color: _getScoreColor(lead.score!, lead.scoreCategory),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score: ${lead.score}',
                            style: TextStyle(
                              color: _getScoreColor(lead.score!, lead.scoreCategory),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (lead.score != null)
                const SizedBox(height: 12),
              
              // Contact Information
              if (lead.email != null || lead.phone != null)
                Row(
                  children: [
                    if (lead.email != null)
                      Expanded(
                        child: _buildInfoRow(
                          context,
                          Icons.email_outlined,
                          Helpers.safeDisplayString(lead.email),
                          theme.colorScheme.primary,
                        ),
                      ),
                    if (lead.email != null && lead.phone != null)
                      const SizedBox(width: 8),
                    if (lead.phone != null)
                      Expanded(
                        child: _buildInfoRow(
                          context,
                          Icons.phone_outlined,
                          Helpers.safeDisplayString(lead.phone),
                          theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              if (lead.email != null || lead.phone != null)
                const SizedBox(height: 8),
              
              // Categories
              if (lead.categories.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: lead.categories
                      .whereType<CategoryModel>()
                      .take(3)
                      .map((category) {
                    final categoryColor = category.color != null &&
                            category.color!.isNotEmpty
                        ? Color(int.parse(
                            category.color!.replaceFirst('#', '0xFF')))
                        : Colors.grey;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Helpers.safeDisplayString(category.name),
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(
    LeadWithRelationsModel lead,
    LeadController leadController,
    Color statusColor,
  ) {
    return Container(
      height: 32, // Fixed height to match assigned-to widget
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(lead.status),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _getStatusLabel(lead.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Only show dropdown if status can be edited
          // Show if: canEditStatus is true (overrides isReadOnly for status)
          if (canEditStatus)
            PopupMenuButton<LeadStatus>(
              icon: Icon(Icons.arrow_drop_down, size: 18, color: statusColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (newStatus) async {
              final input = CreateLeadInput(
                name: lead.name,
                email: lead.email,
                phone: lead.phone,
                whatsapp: lead.whatsapp,
                company: lead.company,
                address: lead.address,
                occupation: lead.occupation,
                fieldOfWork: lead.fieldOfWork,
                source: lead.source,
                notes: lead.notes,
                status: newStatus,
                assignedTo: lead.assignedTo,
                categoryIds: lead.categories.map((c) => c.id).toList(),
                products: lead.products,
              );
              final success = await leadController.updateLead(lead.id, input);
              if (success) {
                Get.snackbar(
                  'Success',
                  'Status updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'Error',
                  leadController.errorMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            itemBuilder: (context) => LeadStatus.values.map((status) {
              final color = _getStatusColor(status);
              return PopupMenuItem<LeadStatus>(
                value: status,
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusLabel(status),
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedToDropdown(
    BuildContext context,
    LeadWithRelationsModel lead,
    LeadController leadController,
    StaffController staffController,
  ) {
    final theme = Theme.of(context);
    final assignedColor = lead.assignedUser != null 
        ? theme.colorScheme.primary 
        : theme.colorScheme.onSurfaceVariant;
    final rawName = lead.assignedUser?.name;
    final assignedName = (rawName == null || rawName.isEmpty)
        ? 'Unassigned'
        : Helpers.safeDisplayString(rawName);
    
    return Container(
      height: 32, // Fixed height to match status widget
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: assignedColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: assignedColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 14,
            color: assignedColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              assignedName,
              style: TextStyle(
                color: assignedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Only show dropdown if assigned to can be edited
          // Show if: canEditAssignedTo is true (overrides isReadOnly for assigned to)
          if (canEditAssignedTo)
            PopupMenuButton<String?>(
              icon: Icon(Icons.arrow_drop_down, size: 18, color: assignedColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (newAssignedTo) async {
              final input = CreateLeadInput(
                name: lead.name,
                email: lead.email,
                phone: lead.phone,
                whatsapp: lead.whatsapp,
                company: lead.company,
                address: lead.address,
                occupation: lead.occupation,
                fieldOfWork: lead.fieldOfWork,
                source: lead.source,
                notes: lead.notes,
                status: lead.status,
                assignedTo: newAssignedTo,
                categoryIds: lead.categories.map((c) => c.id).toList(),
                products: lead.products,
              );
              final success = await leadController.updateLead(lead.id, input);
              if (success) {
                Get.snackbar(
                  'Success',
                  'Assignment updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'Error',
                  leadController.errorMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            itemBuilder: (context) {
              final theme = Theme.of(context);
              final items = <PopupMenuItem<String?>>[
                PopupMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.person_off, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Unassigned', style: TextStyle(color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
              ];
              // Add staff members
              for (final staff in staffController.staffList) {
                items.add(
                  PopupMenuItem<String?>(
                    value: staff.id,
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(Helpers.safeDisplayString(staff.name), style: TextStyle(color: theme.colorScheme.onSurface)),
                      ],
                    ),
                  ),
                );
              }
              return items;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(String whatsappNumber) async {
    try {
      // Remove all non-numeric characters except + at the start
      String cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Check if number already has country code
      bool hasCountryCode = cleanNumber.startsWith('+');
      
      if (hasCountryCode) {
        // Remove + for URL (wa.me doesn't need +)
        cleanNumber = cleanNumber.substring(1);
      } else {
        // Remove leading 0 if present
        if (cleanNumber.startsWith('0')) {
          cleanNumber = cleanNumber.substring(1);
        }
        // Add Indian country code +91
        cleanNumber = '91$cleanNumber';
      }
      
      // Ensure we have a valid number
      if (cleanNumber.isEmpty || cleanNumber.length < 10) {
        Get.snackbar(
          'Error',
          'Invalid WhatsApp number',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      final url = Uri.parse('https://wa.me/$cleanNumber');
      
      // Try to launch directly - canLaunchUrl sometimes returns false even when app is installed
      try {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // If external application fails, try platformDefault
        try {
          await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );
        } catch (e2) {
          // If both fail, show error
          Get.snackbar(
            'Error',
            'Could not open WhatsApp. Please make sure WhatsApp is installed.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          debugPrint('Error launching WhatsApp: $e2');
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open WhatsApp: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      debugPrint('Error launching WhatsApp: $e');
    }
  }

}
