# My Tasks Feature Documentation

## Overview
The My Tasks screen displays tasks assigned to or created by the current user, accessible to all roles.

## Key Changes (Jan 2026)

### 1. Visibility Fix
- **Before**: My Tasks tab only visible to staff roles
- **After**: My Tasks tab visible to ALL roles (shop_owner, admin, staff)

### 2. Query Fix
The task fetching now includes tasks where user is either:
- `assigned_to` (tasks assigned to them)
- `performed_by` (tasks they created)

```dart
.or('assigned_to.eq.$userId,performed_by.eq.$userId')
```

### 3. Bottom Navigation (5-item limit)
The animated_notch_bottom_bar library has a max 5 items limit.

| Role | Tab Structure |
|------|---------------|
| Admin/Owner | Dashboard, Leads, My Tasks, Staff, Settings |
| Staff | Dashboard, Leads, My Tasks, Categories, Settings |

> **Note**: For admin, Categories is only accessible via drawer (opens via route).

### 4. Task Card Design
Simplified to match website:
- Priority indicator dot
- Title + Description
- Due date, Lead name, Assigned user, Status badges
- Arrow button → Lead detail page

**Removed**: Edit, Delete, and Complete buttons

### 5. Timezone Fix
All dates converted from UTC to local time using `.toLocal()` in `activity_model.dart`.

## Files Modified
- `lib/data/repositories/activity_repository.dart` - Query fix
- `lib/data/models/activity_model.dart` - Timezone fix  
- `lib/presentation/views/home/home_view.dart` - Navigation fix
- `lib/presentation/views/tasks/my_tasks_view.dart` - Task card redesign
