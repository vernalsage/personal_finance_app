import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/export_service.dart';
import 'repository_providers.dart';

/// Provider for CSVExportService
final exportServiceProvider = Provider<CSVExportService>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return CSVExportService(transactionRepository);
});
