import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/user_card_widget.dart';
import '../../widgets/shop_card_widget.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Obx(() {
        if (authController.user == null || authController.shop == null) {
          return const Center(
            child: Text('No user data available'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              UserCardWidget(user: authController.user!),
              const SizedBox(height: 16),
              ShopCardWidget(shop: authController.shop!),
            ],
          ),
        );
      }),
    );
  }
}

