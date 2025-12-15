# Supporta CRM - Flutter App

A Flutter application built with GetX state management, MVVM architecture, and Supabase backend.

## Architecture

This project follows **MVVM (Model-View-ViewModel)** architecture with **GetX** for state management:

```
lib/
├── app/                    # App configuration
│   ├── routes/            # Route definitions
│   ├── bindings/         # Dependency injection
│   └── theme/            # App theming
├── core/                  # Core utilities
│   ├── constants/        # App constants
│   ├── services/         # Core services (Supabase)
│   ├── utils/            # Helper functions
│   └── widgets/          # Reusable widgets
├── data/                  # Data layer
│   ├── models/           # Data models
│   └── repositories/     # Data repositories
├── viewmodels/           # ViewModels (business logic)
└── presentation/         # Presentation layer
    ├── controllers/      # GetX controllers
    ├── views/            # Screen widgets
    └── widgets/          # Screen-specific widgets
```

## Features

- ✅ GetX State Management
- ✅ MVVM Architecture
- ✅ Supabase Integration
- ✅ Reusable Widget Components
- ✅ Clean Code Structure
- ✅ Error Handling
- ✅ Authentication Flow

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

1. Get your Supabase credentials from your project dashboard
2. Open `lib/core/constants/app_constants.dart`
3. Update the following:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Run the App

```bash
flutter run
```

## Project Structure

### Core Components

- **Constants**: App-wide constants and configuration
- **Services**: Supabase service wrapper
- **Utils**: Helper functions for validation, formatting, etc.
- **Widgets**: Reusable UI components

### Data Layer

- **Models**: Data classes representing entities
- **Repositories**: Data access layer using Supabase

### Presentation Layer

- **Controllers**: GetX controllers managing state
- **Views**: Screen widgets (kept minimal)
- **Widgets**: Screen-specific reusable widgets

### ViewModels

- Business logic layer between Controllers and Repositories

## Adding New Features

### 1. Create a Model

```dart
// lib/data/models/example_model.dart
class ExampleModel {
  final String id;
  final String name;
  
  ExampleModel({required this.id, required this.name});
  
  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      id: json['id'],
      name: json['name'],
    );
  }
}
```

### 2. Create a Repository

```dart
// lib/data/repositories/example_repository.dart
class ExampleRepository extends BaseRepository {
  Future<List<ExampleModel>> getExamples() async {
    final data = await getAll('examples');
    return data.map((json) => ExampleModel.fromJson(json)).toList();
  }
}
```

### 3. Create a ViewModel

```dart
// lib/viewmodels/example_viewmodel.dart
class ExampleViewModel {
  final ExampleRepository _repository = ExampleRepository();
  
  Future<List<ExampleModel>> fetchExamples() async {
    return await _repository.getExamples();
  }
}
```

### 4. Create a Controller

```dart
// lib/presentation/controllers/example_controller.dart
class ExampleController extends GetxController {
  final ExampleViewModel _viewModel = ExampleViewModel();
  final _examples = <ExampleModel>[].obs;
  
  List<ExampleModel> get examples => _examples;
  
  @override
  void onInit() {
    super.onInit();
    loadExamples();
  }
  
  Future<void> loadExamples() async {
    _examples.value = await _viewModel.fetchExamples();
  }
}
```

### 5. Create a View

```dart
// lib/presentation/views/example/example_view.dart
class ExampleView extends StatelessWidget {
  const ExampleView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExampleController>(
      init: ExampleController(),
      builder: (controller) => ExampleListWidget(controller: controller),
    );
  }
}
```

### 6. Create Reusable Widgets

Break down the view into smaller widgets:

```dart
// lib/presentation/views/example/widgets/example_list_widget.dart
class ExampleListWidget extends StatelessWidget {
  final ExampleController controller;
  
  const ExampleListWidget({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
      itemCount: controller.examples.length,
      itemBuilder: (context, index) {
        return ExampleItemWidget(example: controller.examples[index]);
      },
    ));
  }
}
```

## Converting Website to Flutter

When you have access to the website repository:

1. **Analyze the website structure**:
   - Identify all screens/pages
   - List all API endpoints
   - Note UI components and their functionality

2. **Map to Flutter**:
   - Each page → View + Controller + ViewModel
   - Each API call → Repository method
   - Each UI component → Reusable widget

3. **Create Models**:
   - Convert TypeScript/JavaScript interfaces to Dart models
   - Add fromJson/toJson methods

4. **Implement Features**:
   - Start with authentication
   - Add core features one by one
   - Keep widgets small and reusable

## Best Practices

1. **Keep files small**: Each file should have a single responsibility
2. **Reusable widgets**: Extract common UI patterns into widgets
3. **Error handling**: Always handle errors gracefully
4. **Type safety**: Use proper types, avoid dynamic when possible
5. **Code organization**: Follow the MVVM structure strictly

## Dependencies

- `get`: State management and routing
- `supabase_flutter`: Backend integration
- `get_storage`: Local storage
- `flutter_svg`: SVG support
- `cached_network_image`: Image caching
- `intl`: Internationalization
- `logger`: Logging utility

## Notes

- The base repository uses dynamic typing for Supabase queries to handle type system limitations
- After running `flutter pub get`, verify all imports work correctly
- Adjust Supabase query methods if needed based on your package version

## License

[Your License Here]
