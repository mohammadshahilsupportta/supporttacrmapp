import 'package:flutter/material.dart';
import '../../../../data/models/staff_model.dart';
import '../../../../data/models/user_model.dart';

class StaffCardWidget extends StatelessWidget {
  final StaffWithPermissionsModel staff;
  final VoidCallback? onTap;

  const StaffCardWidget({
    super.key,
    required this.staff,
    this.onTap,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Chip(
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
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: staff.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (staff.categoryPermissions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: staff.categoryPermissions.map((category) {
                    return Chip(
                      label: Text(
                        category.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: category.color != null
                          ? Color(int.parse(category.color!.replaceFirst('#', '0xFF')))
                              .withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

