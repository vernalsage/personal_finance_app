import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'merchant_details_screen.dart';
import '../../providers/merchant_providers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/style/app_colors.dart';
import '../../../main.dart';

class MerchantsScreen extends ConsumerWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: const Text('Merchants'),
      ),
      body: merchantsAsync.when(
        data: (merchants) => merchants.isEmpty
            ? _buildEmptyState(context)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: merchants.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final merchant = merchants[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border(isDark)),
                    ),
                    tileColor: AppColors.surface(isDark),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: Text(merchant.name),
                    subtitle: Text(merchant.hasDefaultCategory ? 'Categorized Merchant' : 'User Added'),
                    trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary(isDark)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MerchantDetailsScreen(merchant: merchant),
                        ),
                      );
                    },
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => ErrorDisplayWidget(
          error: err.toString(),
          onRetry: () => ref.invalidate(merchantsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No merchants tracked yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
