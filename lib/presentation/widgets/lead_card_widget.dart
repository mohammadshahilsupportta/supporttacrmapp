import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(lead.status);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 200, // Fixed height for uniform cards (increased to prevent overflow)
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Avatar, Name and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Circle
                  Container(
                    width: 44, // Slightly smaller
                    height: 44,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lead.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusLabel(lead.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Reduced spacing
              
              // Contact Information - Fixed height section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First row: Email and Phone
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            Icons.email_outlined,
                            lead.email ?? 'No email',
                            Colors.blue,
                            isPlaceholder: lead.email == null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            Icons.phone_outlined,
                            lead.phone ?? 'No phone',
                            Colors.green,
                            isPlaceholder: lead.phone == null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    // Second row: Company or Assigned User
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            lead.company != null
                                ? Icons.business_outlined
                                : Icons.person_outline,
                            lead.company ?? 
                                (lead.assignedUser?.name ?? 'Unassigned'),
                            lead.company != null ? Colors.purple : Colors.orange,
                            isPlaceholder: lead.company == null && 
                                lead.assignedUser == null,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Categories - Always at bottom
                    if (lead.categories.isNotEmpty)
                      SizedBox(
                        height: 20, // Reduced height
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: lead.categories
                              .whereType<CategoryModel>()
                              .take(3) // Limit to 3 categories
                              .map((category) {
                            final categoryColor = category.color != null &&
                                    category.color!.isNotEmpty
                                ? Color(int.parse(
                                    category.color!.replaceFirst('#', '0xFF')))
                                : Colors.grey;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
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
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: categoryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      const SizedBox(height: 20), // Reduced height
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color color, {
    bool isPlaceholder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12, // Smaller icon
            color: isPlaceholder ? Colors.grey : color,
          ),
          const SizedBox(width: 4), // Reduced spacing
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10, // Smaller font
                fontWeight: FontWeight.w500,
                color: isPlaceholder ? Colors.grey : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
