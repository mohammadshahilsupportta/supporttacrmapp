import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../widgets/lead_card_widget.dart';
import '../../../app/routes/app_routes.dart';

class LeadsListView extends StatelessWidget {
  const LeadsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final leadController = Get.put(LeadController());

    // Load leads on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.shop != null) {
        leadController.loadLeads(authController.shop!.id);
        leadController.loadStats(authController.shop!.id);
      }
    });

    return Obx(() {
        if (leadController.isLoading && leadController.leads.isEmpty) {
          return const LoadingWidget();
        }

        if (leadController.errorMessage.isNotEmpty) {
          return error_widget.ErrorDisplayWidget(
            message: leadController.errorMessage,
            onRetry: () {
              if (authController.shop != null) {
                leadController.loadLeads(authController.shop!.id);
              }
            },
          );
        }

        if (leadController.leads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No leads found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Start by adding your first lead'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.LEAD_CREATE);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lead'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (authController.shop != null) {
              await leadController.loadLeads(authController.shop!.id);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leadController.leads.length,
            itemBuilder: (context, index) {
              final lead = leadController.leads[index];
              return LeadCardWidget(
                lead: lead,
                onTap: () {
                  Get.toNamed(
                    AppRoutes.LEAD_DETAIL.replaceAll(':id', lead.id),
                  );
                },
              );
            },
          ),
        );
    });
  }
}


