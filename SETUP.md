# Setup Guide for Converting Website to Flutter App

## Step 1: Access the Website Repository

Since the repository `https://github.com/supportta-projects/supporttacrmweb.git` is private, you'll need to:

1. **Clone it locally** (if you have access):
   ```bash
   git clone https://github.com/supportta-projects/supporttacrmweb.git
   ```

2. **Or provide the code** in another way

## Step 2: Analyze the Website Structure

Once you have the website code, identify:

### Pages/Screens
- List all routes/pages
- Note their functionality
- Identify shared components

### API Integration
- List all API endpoints
- Note request/response formats
- Identify authentication methods

### UI Components
- List reusable components
- Note styling patterns
- Identify form components

### State Management
- How state is managed (Redux, Context, etc.)
- Identify global state vs local state

## Step 3: Map to Flutter Structure

### For Each Page:

1. **Create View** (`lib/presentation/views/[page_name]/[page_name]_view.dart`)
   - Minimal code, just sets up the controller

2. **Create Controller** (`lib/presentation/controllers/[page_name]_controller.dart`)
   - Manages state with GetX observables
   - Calls ViewModel methods

3. **Create ViewModel** (`lib/viewmodels/[page_name]_viewmodel.dart`)
   - Contains business logic
   - Calls Repository methods

4. **Create Repository** (`lib/data/repositories/[page_name]_repository.dart`)
   - Extends BaseRepository
   - Implements Supabase queries

5. **Create Model** (`lib/data/models/[entity]_model.dart`)
   - Data classes with fromJson/toJson

6. **Create Widgets** (`lib/presentation/views/[page_name]/widgets/`)
   - Break down UI into small reusable widgets
   - Each widget should be < 100 lines ideally

## Step 4: Convert Supabase Queries

If the website uses Supabase:

1. **Identify tables** used in the website
2. **Map queries** to repository methods
3. **Update RLS policies** if needed
4. **Test each query** in Flutter

## Step 5: Convert UI Components

### Common Conversions:

**React/Vue Component** → **Flutter Widget**
- `div` → `Container` or `SizedBox`
- `button` → `ElevatedButton` or `CustomButton`
- `input` → `CustomTextField`
- `img` → `Image` or `CachedNetworkImage`

### Styling:
- CSS → Flutter `Theme` or inline styles
- CSS classes → Reusable widget parameters

## Step 6: Testing Checklist

- [ ] Authentication flow works
- [ ] All screens are accessible
- [ ] Data loads correctly
- [ ] Forms submit properly
- [ ] Error handling works
- [ ] Navigation flows correctly
- [ ] UI is responsive

## Example Conversion

### Website (React):
```jsx
function UserList() {
  const [users, setUsers] = useState([]);
  
  useEffect(() => {
    fetchUsers().then(setUsers);
  }, []);
  
  return (
    <div>
      {users.map(user => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  );
}
```

### Flutter Equivalent:

**Controller:**
```dart
class UserController extends GetxController {
  final UserViewModel _viewModel = UserViewModel();
  final _users = <UserModel>[].obs;
  
  List<UserModel> get users => _users;
  
  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }
  
  Future<void> loadUsers() async {
    _users.value = await _viewModel.fetchUsers();
  }
}
```

**View:**
```dart
class UserListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserController>(
      init: UserController(),
      builder: (controller) => UserListWidget(controller: controller),
    );
  }
}
```

**Widget:**
```dart
class UserListWidget extends StatelessWidget {
  final UserController controller;
  
  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
      itemCount: controller.users.length,
      itemBuilder: (context, index) {
        return UserCardWidget(user: controller.users[index]);
      },
    ));
  }
}
```

## Next Steps

1. Start with authentication
2. Convert one page at a time
3. Test each feature as you go
4. Refactor as needed to keep code clean


