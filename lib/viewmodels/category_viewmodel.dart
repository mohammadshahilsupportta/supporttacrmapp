import '../data/repositories/category_repository.dart';
import '../data/models/category_model.dart';

class CategoryViewModel {
  final CategoryRepository _repository = CategoryRepository();

  // Get all categories
  Future<List<CategoryModel>> getCategories(String shopId) async {
    return await _repository.findAll(shopId);
  }

  // Get category by ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    return await _repository.findById(categoryId);
  }

  // Create category
  Future<CategoryModel> createCategory(
    String shopId,
    CreateCategoryInput input,
  ) async {
    return await _repository.create(shopId, input);
  }

  // Update category
  Future<CategoryModel> updateCategory(UpdateCategoryInput input) async {
    return await _repository.update(input);
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    await _repository.delete(categoryId);
  }
}


