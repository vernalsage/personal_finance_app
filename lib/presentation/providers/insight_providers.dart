import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/usecase_providers.dart';
import '../../domain/core/result.dart';

/// Provider for expense breakdown by category
final expenseBreakdownProvider = FutureProvider.family<Map<String, int>, ({DateTime start, DateTime end})>((ref, range) async {
  final getBreakdown = ref.read(getExpenseBreakdownUseCaseProvider);
  final result = await getBreakdown(
    profileId: 1,
    startDate: range.start,
    endDate: range.end,
  );
  
  if (result.isFailure) {
    throw result.failureData!;
  }
  
  return result.successData!;
});

/// Provider for weekly spending pattern (last 7 days)
final weeklySpendingProvider = FutureProvider<List<int>>((ref) async {
  final getWeekly = ref.read(getWeeklySpendingUseCaseProvider);
  final result = await getWeekly(
    profileId: 1,
    endDate: DateTime.now(),
  );
  
  if (result.isFailure) {
    throw result.failureData!;
  }
  
  return result.successData!;
});
