import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/staff_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import 'widgets/staff_card_widget.dart';

class StaffListView extends StatelessWidget {
  const StaffListView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final staffController = Get.put(StaffController());

    // Load staff when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.shop != null) {
        staffController.loadStaff(authController.shop!.id);
      }
    });

    return Obx(() {
        if (staffController.isLoading && staffController.staffList.isEmpty) {
          return const LoadingWidget();
        }

        if (staffController.errorMessage.isNotEmpty) {
          return error_widget.ErrorDisplayWidget(
            message: staffController.errorMessage,
            onRetry: () {
              if (authController.shop != null) {
                staffController.loadStaff(authController.shop!.id);
              }
            },
          );
        }

        if (staffController.staffList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No staff members yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first staff member to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (authController.shop != null) {
              await staffController.loadStaff(authController.shop!.id);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffController.staffList.length,
            itemBuilder: (context, index) {
              final staff = staffController.staffList[index];
              return StaffCardWidget(
                staff: staff,
                onTap: () {
                  // Navigate to staff detail page
                  // Get.toNamed(AppRoutes.STAFF_DETAIL, arguments: staff.id);
                },
              );
            },
          ),
        );
    });
  }
}

