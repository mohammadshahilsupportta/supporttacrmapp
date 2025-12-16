import 'package:get/get.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../data/models/category_model.dart';
import '../../core/utils/helpers.dart';

class CategoryController extends GetxController {
  final CategoryViewModel _viewModel = CategoryViewModel();

  // Observables
  final _categories = <CategoryModel>[].obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _selectedCategory = Rxn<CategoryModel>();

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  CategoryModel? get selectedCategory => _selectedCategory.value;

  // Load categories
  Future<void> loadCategories(String shopId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _viewModel.getCategories(shopId);
      _categories.value = result;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Load category by ID
  Future<void> loadCategoryById(String categoryId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _viewModel.getCategoryById(categoryId);
      _selectedCategory.value = result;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Create category
  Future<bool> createCategory(String shopId, CreateCategoryInput input) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.createCategory(shopId, input);
      await loadCategories(shopId);
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update category
  Future<bool> updateCategory(UpdateCategoryInput input, {String? shopId}) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.updateCategory(input);
      // Reload the categories list to refresh the UI
      if (shopId != null) {
        await loadCategories(shopId);
      } else {
        // If shopId not provided, update the category in the list manually
        final index = _categories.indexWhere((c) => c.id == input.id);
        if (index != -1) {
          await loadCategoryById(input.id);
          final updated = _selectedCategory.value;
          if (updated != null) {
            _categories[index] = updated;
          }
        }
      }
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId, String shopId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.deleteCategory(categoryId);
      await loadCategories(shopId);
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}


