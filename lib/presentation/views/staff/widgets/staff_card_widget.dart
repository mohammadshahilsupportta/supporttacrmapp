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
    switch (role) {
      case UserRole.shopOwner:
        return Colors.purple;
      case UserRole.admin:
        return Colors.blue;
      case UserRole.marketingManager:
        return Colors.green;
      case UserRole.officeStaff:
        return Colors.orange;
      case UserRole.freelance:
        return Colors.teal;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(staff.role);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 64,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: roleColor.withOpacity(0.12),
                              child: Text(
                                staff.name
                                    .split(' ')
                                    .map((n) => n.isNotEmpty ? n[0] : '')
                                    .join('')
                                    .toUpperCase()
                                    .substring(
                                      0,
                                      staff.name.split(' ').length > 1 ? 2 : 1,
                                    ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    staff.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _pill(
                                        theme,
                                        icon: _getRoleIcon(staff.role),
                                        label: UserModel.roleDisplayName(staff.role),
                                        color: roleColor,
                                      ),
                                      const SizedBox(width: 8),
                                      _pill(
                                        theme,
                                        icon: staff.isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        label: staff.isActive ? 'Active' : 'Inactive',
                                        color: staff.isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant),
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
                              ),
                              const SizedBox(width: 8),
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
                              SizedBox(width: 8),
                              Text('Manage Categories'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
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
              const SizedBox(height: 12),
              if (staff.categoryPermissions.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: staff.categoryPermissions.take(3).map((category) {
                    final catColor = category.color != null
                        ? Color(
                            int.parse(category.color!.replaceFirst('#', '0xFF')))
                        : theme.colorScheme.primary;
                    return Chip(
                      label: Text(
                        category.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: catColor.withOpacity(0.14),
                      side: BorderSide(color: catColor.withOpacity(0.35)),
                    );
                  }).toList(),
                ),
                if (staff.categoryPermissions.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${staff.categoryPermissions.length - 3} more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ] else ...[
                Text(
                  _getCategoryAccessText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
