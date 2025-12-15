import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class UserCardWidget extends StatelessWidget {
  final UserModel user;

  const UserCardWidget({super.key, required this.user});

  String get _userInitials {
    return user.name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join('')
        .toUpperCase()
        .substring(0, user.name.split(' ').length > 1 ? 2 : 1);
  }

  String get _roleDisplay {
    return UserModel.roleDisplayName(user.role);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(_userInitials, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(_roleDisplay), padding: EdgeInsets.zero),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
