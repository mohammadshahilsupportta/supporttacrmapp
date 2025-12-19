import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../controllers/lead_controller.dart';
import '../controllers/staff_controller.dart';
import '../../data/models/lead_model.dart';
import '../../data/models/category_model.dart';

class LeadCardWidget extends StatelessWidget {
  final LeadWithRelationsModel lead;
  final VoidCallback? onTap;

  const LeadCardWidget({super.key, required this.lead, this.onTap});

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.contacted:
        return Colors.orange;
      case LeadStatus.qualified:
        return Colors.purple;
      case LeadStatus.converted:
        return Colors.green;
      case LeadStatus.lost:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Icons.fiber_new;
      case LeadStatus.contacted:
        return Icons.phone;
      case LeadStatus.qualified:
        return Icons.verified;
      case LeadStatus.converted:
        return Icons.check_circle;
      case LeadStatus.lost:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.converted:
        return 'Converted';
      case LeadStatus.lost:
        return 'Lost';
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
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lead.name.isNotEmpty
                            ? lead.name[0].toUpperCase()
                            : 'L',
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
                          lead.name,
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(lead.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
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
                          color: Colors.blue,
                          tooltip: 'Call ${lead.phone}',
                          onPressed: () => _launchPhone(lead.phone!),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (lead.whatsapp != null && lead.whatsapp!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.chat, size: 20),
                          color: Colors.green,
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
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Assigned To',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
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
                        child: _buildAssignedToDropdown(lead, leadController, staffController),
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
                        color: _getScoreColor(lead.score!, lead.scoreCategory).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getScoreColor(lead.score!, lead.scoreCategory).withOpacity(0.3),
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
                          lead.email!,
                          Colors.blue,
                        ),
                      ),
                    if (lead.email != null && lead.phone != null)
                      const SizedBox(width: 8),
                    if (lead.phone != null)
                      Expanded(
                        child: _buildInfoRow(
                          context,
                          Icons.phone_outlined,
                          lead.phone!,
                          Colors.green,
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
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
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
                            category.name,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
    LeadWithRelationsModel lead,
    LeadController leadController,
    StaffController staffController,
  ) {
    final assignedColor = lead.assignedUser != null ? Colors.orange : Colors.grey;
    final assignedName = lead.assignedUser?.name ?? 'Unassigned';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: assignedColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: assignedColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              final items = <PopupMenuItem<String?>>[
                PopupMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.person_off, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Unassigned'),
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
                        Icon(Icons.person, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(staff.name),
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
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(String whatsappNumber) async {
    // Remove all non-numeric characters
    final cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanNumber');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Error launching WhatsApp: $e');
    }
  }

}
