# Role-Based Access Control

## User Roles
1. **shop_owner** - Full access to all features
2. **admin** - Full access to all features
3. **office_staff** - Staff role with limited access
4. **marketing_manager** - Staff role with limited access
5. **freelance** - Staff role with limited access

## Feature Access Matrix

| Feature | shop_owner | admin | office_staff | marketing_manager | freelance |
|---------|------------|-------|--------------|-------------------|-----------|
| Dashboard | ✓ | ✓ | ✓ | ✓ | ✓ |
| Leads (all) | ✓ | ✓ | Own only | Own only | Own only |
| My Tasks | ✓ | ✓ | ✓ | ✓ | ✓ |
| Staff Management | ✓ | ✓ | ✗ | ✗ | ✗ |
| Categories | ✓ | ✓ | ✓ | ✓ | ✓ |
| Settings | ✓ | ✓ | ✓ | ✓ | ✓ |

## Navigation Visibility

### Bottom Bar (max 5 items)
- **Admin/Owner**: Dashboard, Leads, My Tasks, Staff, Settings
  - Categories accessible via drawer only
- **Staff**: Dashboard, Leads, My Tasks, Categories, Settings

### Drawer Menu
All items visible based on role permissions, including Categories for admin.

## Implementation
Role checks in `home_view.dart`:
```dart
bool _canViewStaff(UserModel? user) {
  return user?.role == UserRole.shopOwner || 
         user?.role == UserRole.admin;
}

bool _isStaffRole(UserModel? user) {
  return user?.role != UserRole.shopOwner && 
         user?.role != UserRole.admin;
}
```
