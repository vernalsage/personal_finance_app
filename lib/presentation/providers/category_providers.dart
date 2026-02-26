import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';

import '../../core/di/repository_providers.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categoryRepository = ref.read(categoryRepositoryProvider);
  // Default to profileId 1 for MVP
  final result = await categoryRepository.getCategories(1);
  
  if (result.isSuccess) {
    return result.successData!;
  }
  
  throw Exception(result.failureData?.toString() ?? 'Failed to load categories');
});
