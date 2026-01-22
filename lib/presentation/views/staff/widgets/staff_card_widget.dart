import 'package:flutter/material.dart';
import '../../../../data/models/staff_model.dart';
import '../../../../data/models/user_model.dart';

class StaffCardWidget extends StatelessWidget {
  final StaffWithPermissionsModel staff;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;
  final VoidCallback? onManageCategories;
  final VoidCallback? onDelete;
  final bool canManage;

  const StaffCardWidget({
    super.key,
    required this.staff,
    this.onTap,
    this.onToggleActive,
    this.onManageCategories,
    this.onDelete,
    this.canManage = false,
  });

  Color _getRoleColor(UserRole role) {
    // Use same simple Material colors as lead cards for consistency
    switch (role) {
      case UserRole.shopOwner:
        return Colors.purple; // Same as qualified leads
      case UserRole.admin:
        return Colors.blue; // Same as new leads
      case UserRole.marketingManager:
        return Colors.green; // Same as converted leads
      case UserRole.officeStaff:
        return Colors.blue; // Same blue as used in leads screen
      case UserRole.freelance:
        return Colors.teal; // Professional teal
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.shopOwner:
        return Icons.shield;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.marketingManager:
        return Icons.trending_up;
      case UserRole.officeStaff:
        return Icons.business_center;
      case UserRole.freelance:
        return Icons.person;
    }
  }

  String _getCategoryAccessText() {
    if (staff.role == UserRole.marketingManager ||
        staff.role == UserRole.admin ||
        staff.role == UserRole.shopOwner) {
      return 'All categories';
    }
    if (staff.categoryPermissions.isEmpty) {
      return 'No categories';
    }
    return '${staff.categoryPermissions.length} category${staff.categoryPermissions.length != 1 ? 's' : ''}';
  }

  String _getUserInitials() {
    final parts = staff.name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(staff.role);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.03),
                theme.colorScheme.primary.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Avatar, Name, Role Badge, and Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Circle - same style as lead card
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getUserInitials(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          staff.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Email chip
                        _buildInfoChip(
                          context,
                          Icons.email_outlined,
                          staff.email,
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        // Role and Status badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildRoleBadge(theme, roleColor),
                            _buildStatusBadge(theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  if (canManage)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'toggle':
                            onToggleActive?.call();
                            break;
                          case 'categories':
                            onManageCategories?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                staff.isActive
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                size: 20,
                                color: staff.isActive ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(staff.isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'categories',
                          child: Row(
                            children: [
                              Icon(Icons.folder_open, size: 20),
                              SizedBox(width: 12),
                              Text('Manage Categories'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Category Access Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Category Access',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (staff.categoryPermissions.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: staff.categoryPermissions.take(4).map((category) {
                          final catColor = category.color != null &&
                                  category.color!.isNotEmpty
                              ? Color(int.parse(
                                  category.color!.replaceFirst('#', '0xFF')))
                              : roleColor;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: catColor.withValues(alpha: 0.3),
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
                                    color: catColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    color: catColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      if (staff.categoryPermissions.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+${staff.categoryPermissions.length - 4} more categories',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ] else ...[
                      Text(
                        _getCategoryAccessText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, Color roleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(staff.role),
            size: 14,
            color: roleColor,
          ),
          const SizedBox(width: 6),
          Text(
            UserModel.roleDisplayName(staff.role),
            style: TextStyle(
              color: roleColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final isActive = staff.isActive;
    final statusColor = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
