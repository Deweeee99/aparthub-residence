import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/white_premium_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../models/service_request_models.dart';
import '../service_request_flow_scope.dart';
import '../service_request_routes.dart';
import '../utils/service_request_helpers.dart';
import '../widgets/service_request_screen_scaffold.dart';
import '../widgets/service_request_shared_widgets.dart';

class ServiceCreateRequestPage extends StatefulWidget {
  const ServiceCreateRequestPage({super.key});

  @override
  State<ServiceCreateRequestPage> createState() =>
      _ServiceCreateRequestPageState();
}

class _ServiceCreateRequestPageState extends State<ServiceCreateRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ServiceRequestFlowScope.of(context);
      if (controller.catalog == null && !controller.isLoadingCatalog) {
        controller.loadCatalog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ServiceRequestFlowScope.of(context);

    return ServiceRequestScreenScaffold(
      onRefresh: controller.loadCatalog,
      onBack: () => context.go(ServiceRequestRoutes.services),
      child: ServiceCreateStepPage(
        catalog: controller.catalog,
        selectedCategory: controller.selectedCategory,
        selectedSubcategory: controller.selectedSubcategory,
        isLoading: controller.isLoadingCatalog,
        errorMessage: controller.errorMessage,
        onRetry: controller.loadCatalog,
        onCategorySelected: controller.selectCategory,
        onSubcategorySelected: controller.selectSubcategory,
        onContinue: () => context.push(ServiceRequestRoutes.describe),
      ),
    );
  }
}

class ServiceCreateStepPage extends StatelessWidget {
  const ServiceCreateStepPage({
    super.key,
    required this.catalog,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
    required this.onContinue,
  });

  final ServiceRequestCatalog? catalog;
  final ServiceCategory? selectedCategory;
  final ServiceSubcategory? selectedSubcategory;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<ServiceCategory> onCategorySelected;
  final ValueChanged<ServiceSubcategory> onSubcategorySelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return ServiceRequestLoadingStateCard(
        message: l10n.loadingServiceCatalog,
      );
    }

    if (catalog == null && errorMessage != null) {
      return ServiceRequestErrorStateCard(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    final loadedCatalog = catalog;
    if (loadedCatalog == null) {
      return ServiceRequestErrorStateCard(
        message: l10n.failedToLoad,
        onRetry: onRetry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.whatServiceNeeded,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final category in loadedCatalog.categories)
          ServiceRequestCategoryCard(
            title: category.name,
            subtitle: '${category.subcategories.length} ${l10n.serviceOptions}',
            icon: serviceCategoryIcon(category.name),
            selected: selectedCategory?.id == category.id,
            onTap: () => onCategorySelected(category),
          ),
        if (selectedCategory != null) ...[
          const SizedBox(height: 8),
          WhitePremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chooseSpecificService,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final subcategory in selectedCategory!.subcategories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceRequestCategoryCard(
                      title: subcategory.name,
                      subtitle: serviceSlaLabel(subcategory.sla),
                      icon: Icons.tune_rounded,
                      selected: selectedSubcategory?.id == subcategory.id,
                      onTap: () => onSubcategorySelected(subcategory),
                    ),
                  ),
                ServiceRequestPrimaryStateButton(
                  buttonKey: const ValueKey('continue-to-description-button'),
                  label: l10n.continueToDescription,
                  enabled: selectedSubcategory != null,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
