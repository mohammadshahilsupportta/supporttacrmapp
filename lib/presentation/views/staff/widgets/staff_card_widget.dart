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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
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
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                staff.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
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
                              Text(
                                staff.isActive ? 'Deactivate' : 'Activate',
                              ),
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
              Row(
                children: [
                  Chip(
                    avatar: Icon(
                      _getRoleIcon(staff.role),
                      size: 16,
                      color: _getRoleColor(staff.role),
                    ),
                    label: Text(
                      UserModel.roleDisplayName(staff.role),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getRoleColor(staff.role).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getRoleColor(staff.role),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: staff.isActive,
                    onChanged: canManage ? (value) => onToggleActive?.call() : null,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    staff.isActive ? 'Active' : 'Inactive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (staff.categoryPermissions.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: staff.categoryPermissions.take(3).map((category) {
                    return Chip(
                      label: Text(
                        category.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: category.color != null
                          ? Color(int.parse(
                                  category.color!.replaceFirst('#', '0xFF')))
                              .withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      side: category.color != null
                          ? BorderSide(
                              color: Color(int.parse(
                                  category.color!.replaceFirst('#', '0xFF'))),
                            )
                          : null,
                    );
                  }).toList(),
                ),
                if (staff.categoryPermissions.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Chip(
                      label: Text(
                        '+${staff.categoryPermissions.length - 3} more',
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                    ),
                  ),
              ] else ...[
                Text(
                  _getCategoryAccessText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
