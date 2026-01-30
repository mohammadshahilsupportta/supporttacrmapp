import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../controllers/lead_controller.dart';
import '../controllers/staff_controller.dart';
import '../../data/models/lead_model.dart';
import '../../app/routes/app_routes.dart';

class LeadTableWidget extends StatelessWidget {
  final List<LeadWithRelationsModel> leads;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const LeadTableWidget({
    super.key,
    required this.leads,
    this.isLoading = false,
    this.onRefresh,
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

  Widget _buildStatusBadge(LeadStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        LeadModel.statusToString(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryTags(List categories) {
    if (categories.isEmpty) {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: categories.take(2).map((cat) {
        final categoryColor = cat.color != null && cat.color!.isNotEmpty
            ? Color(int.parse(cat.color!.replaceFirst('#', '0xFF')))
            : Colors.grey;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: categoryColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            cat.name,
            style: TextStyle(
              color: categoryColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not make phone call',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
        );
        return;
      }

      final url = Uri.parse('https://wa.me/$cleanNumber');

      // Try to launch directly - canLaunchUrl sometimes returns false even when app is installed
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        // If external application fails, try platformDefault
        try {
          await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (e2) {
          // If both fail, show error
          Get.snackbar(
            'Error',
            'Could not open WhatsApp. Please make sure WhatsApp is installed.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open WhatsApp',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leadController = Get.find<LeadController>();
    final staffController = Get.find<StaffController>();

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No leads found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Try adjusting your filters'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        columns: const [
          DataColumn(
            label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Contact',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Assigned To',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: leads.map((lead) {
          return DataRow(
            onSelectChanged: (selected) {
              if (selected == true) {
                Get.toNamed(AppRoutes.leadDetail.replaceAll(':id', lead.id));
              }
            },
            cells: [
              DataCell(
                GestureDetector(
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.leadDetail.replaceAll(':id', lead.id),
                    );
                  },
                  child: Text(
                    lead.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              DataCell(
                lead.phone != null
                    ? Text(lead.phone!)
                    : const Text('—', style: TextStyle(color: Colors.grey)),
              ),
              DataCell(
                lead.email != null
                    ? Text(lead.email!)
                    : const Text('—', style: TextStyle(color: Colors.grey)),
              ),
              DataCell(_buildStatusDropdown(lead, leadController)),
              DataCell(_buildCategoryTags(lead.categories)),
              DataCell(
                _buildAssignmentDropdown(lead, leadController, staffController),
              ),
              DataCell(
                Text(
                  DateFormat('MMM dd, yyyy').format(lead.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              DataCell(_buildActionButtons(lead)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusDropdown(
    LeadWithRelationsModel lead,
    LeadController leadController,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusBadge(lead.status),
        const SizedBox(width: 4),
        PopupMenuButton<LeadStatus>(
          icon: const Icon(Icons.arrow_drop_down, size: 16),
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
              );
            }
          },
          itemBuilder: (context) => LeadStatus.values.map((status) {
            return PopupMenuItem<LeadStatus>(
              value: status,
              child: Text(LeadModel.statusToString(status)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentDropdown(
    LeadWithRelationsModel lead,
    LeadController leadController,
    StaffController staffController,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lead.assignedUser?.name ?? 'Unassigned',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String?>(
          icon: const Icon(Icons.arrow_drop_down, size: 16),
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
              );
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuItem<String?>>[
              const PopupMenuItem<String?>(
                value: null,
                child: Text('Unassigned'),
              ),
            ];
            // Add staff members
            for (final staff in staffController.staffList) {
              items.add(
                PopupMenuItem<String?>(
                  value: staff.id,
                  child: Text(staff.name),
                ),
              );
            }
            return items;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(LeadWithRelationsModel lead) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lead.phone != null)
          IconButton(
            icon: const Icon(Icons.phone, size: 18),
            onPressed: () => _launchPhone(lead.phone!),
            tooltip: 'Call ${lead.phone}',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (lead.whatsapp != null && lead.whatsapp!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.chat, size: 18, color: Colors.green),
            onPressed: () => _launchWhatsApp(lead.whatsapp!),
            tooltip: 'WhatsApp ${lead.whatsapp}',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
