# Feature Comparison: Website vs Mobile App

## Overview
This document compares all features available in the SupporttaCRM website with the Flutter mobile app to ensure feature parity.

## Feature Status

| Feature | Website | Mobile App | Status |
|---------|---------|------------|--------|
| **Dashboard** | ✅ | ✅ | ✅ Complete |
| **Leads Management** | ✅ | ✅ | ✅ Complete |
| **My Tasks** | ✅ | ✅ | ✅ Complete |
| **Categories** | ✅ | ✅ | ✅ Complete |
| **Staff Management** | ✅ | ✅ | ✅ Complete |
| **Reports** | ✅ | ✅ | ✅ Complete |
| **Leaderboard** | ✅ | ✅ | ✅ **NEWLY ADDED** (Closed Won leaderboard, all roles) |
| **Customers** | 🟡 (Coming Soon) | ❌ | ⏸️ Not Implemented (Website placeholder) |
| **Settings** | ✅ | ✅ | ✅ Complete |
| **Profile** | ✅ | ✅ | ✅ Complete |
| **Shop Information** | ✅ | ✅ | ✅ Complete |
| **Help & Support** | ✅ | ✅ | ✅ Complete |

## Detailed Feature Breakdown

### ✅ Dashboard
- **Website**: Overview with stats, lead status breakdown, shop/user info
- **App**: Same features with responsive cards and stats widgets
- **Status**: ✅ Complete

### ✅ Leads Management
- **Website**: Full CRUD operations, filtering, search, status management
- **App**: Full CRUD operations, filtering, search, status management, assigned staff
- **Status**: ✅ Complete

### ✅ My Tasks
- **Website**: Calendar view with task indicators, overdue highlighting, task cards
- **App**: Calendar view with task indicators, overdue highlighting, task cards, navigation to lead details
- **Status**: ✅ Complete

### ✅ Categories
- **Website**: Category management with colors, permissions
- **App**: Category management with colors, permissions
- **Status**: ✅ Complete

### ✅ Staff Management
- **Website**: Staff CRUD, role management, category permissions
- **App**: Staff CRUD, role management, category permissions
- **Status**: ✅ Complete

### ✅ Reports
- **Website**: Staff performance analytics with summary cards and staff performance table; role-based access (shop_owner, admin only).
- **App**: Same features; accessible via drawer.
- **Status**: ✅ Complete

### ✅ Leaderboard (NEWLY ADDED)
- **Website**: Closed Won Leaderboard – staff ranked by Closed – Won count; period filter (All time, This month, This week, This day); visible to **all roles**.
- **App**: Same features:
  - Closed Won Leaderboard with period chips (All time, This month, This week, This day)
  - Rankings table (Rank, Name, Role, Closed – Won)
  - Visible to all staff (drawer item for everyone)
  - Supports both DB statuses: `closed_won` (website) and `converted` (app)
- **Status**: ✅ **NEWLY IMPLEMENTED**

### 🟡 Customers
- **Website**: Route exists but shows "Coming Soon" placeholder
- **App**: Not implemented (matches website status)
- **Status**: ⏸️ Pending (Website not fully implemented)

### ✅ Settings
- **Website**: App settings, profile management
- **App**: App settings, theme toggle, profile management
- **Status**: ✅ Complete

### ✅ Profile
- **Website**: User profile view
- **App**: User profile view
- **Status**: ✅ Complete

### ✅ Shop Information
- **Website**: Shop details view
- **App**: Shop details view
- **Status**: ✅ Complete

### ✅ Help & Support
- **Website**: Help and support information
- **App**: Help and support information
- **Status**: ✅ Complete

## Role-Based Access

### Admin/Owner Roles
- ✅ Dashboard
- ✅ Leads (all leads in shop)
- ✅ My Tasks
- ✅ Staff Management
- ✅ Categories
- ✅ **Reports** (NEW)
- ✅ Settings

### Staff Roles
- ✅ Dashboard
- ✅ Leads (filtered by permissions)
- ✅ My Tasks
- ✅ Categories (if permitted)
- ❌ Staff Management
- ❌ **Reports**
- ✅ Settings

## Navigation Structure

### Website Navigation (Sidebar)
- Dashboard
- Leads
- My Tasks
- Categories (role-dependent)
- Customers (role-dependent, coming soon)
- Staff (admin/owner only)
- Reports (admin/owner only)
- Settings

### Mobile App Navigation
- **Bottom Navigation Bar**:
  - Dashboard
  - Leads
  - My Tasks
  - Staff (admin/owner only) OR Categories (staff with permission)
  - Settings
- **Drawer Menu**:
  - All bottom nav items
  - **Leaderboard** (all roles) - NEW
  - Categories (if not in bottom nav)
  - Reports (admin/owner only)
  - Profile
  - Sign Out

## Implementation Notes

### Reports Feature Implementation
1. **Models**: `StaffPerformanceStats`, `ReportSummary`, `TopPerformer`, `LeadsByStatus`, `StaffPerformanceFilters`
2. **Repository**: `ReportRepository` with direct Supabase queries
3. **Controller**: `ReportController` with GetX state management
4. **View**: `ReportsView` with summary cards and performance table
5. **Access Control**: Only shop_owner and admin roles can access

### Data Flow
- Repository queries staff, users, leads, and activities
- Calculates conversion metrics, time-to-convert, and performance stats
- Controller manages loading state and error handling
- View displays data in cards and table format

## Next Steps

1. **Customers Feature**: Wait for website implementation, then add to app
2. **Reports Enhancements**: Consider adding date range filters, export functionality
3. **Performance**: Optimize queries for large datasets
4. **Testing**: Add unit tests for Reports feature

## Summary

✅ **All implemented website features are now available in the mobile app**
✅ **Leaderboard (Closed Won) has been added** – visible to all roles, period filter, same logic as website
✅ **Reports** – staff performance (admin/owner only)
⏸️ **Customers feature pending (website placeholder)**

The mobile app now has feature parity with the website for all implemented features, including the Leaderboard.


