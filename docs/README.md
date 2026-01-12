# SupportaCRM App Documentation

## Overview
SupportaCRM is a Flutter-based CRM mobile application that syncs with the SupportaCRM web platform.

## Project Structure
```
lib/
├── app/
│   ├── routes/       # App routes and pages
│   └── theme/        # App themes
├── core/
│   └── widgets/      # Shared widgets
├── data/
│   ├── models/       # Data models
│   └── repositories/ # Data repositories
└── presentation/
    ├── controllers/  # GetX controllers
    ├── views/        # UI screens
    └── widgets/      # UI widgets
```

## Key Features
- **Dashboard**: Overview with stats and widgets
- **Leads**: Lead management with CRUD operations
- **My Tasks**: Tasks calendar view (all roles)
- **Staff**: Staff management (admin/owner only)
- **Categories**: Lead categories (role-dependent)
- **Settings**: App settings and profile

## Navigation
Uses `AnimatedNotchBottomBar` with max 5 items:
- Admin: Dashboard, Leads, My Tasks, Staff, Settings
- Staff: Dashboard, Leads, My Tasks, Categories, Settings

## State Management
Uses GetX for state management and navigation.

## Backend
Supabase for database and authentication.
