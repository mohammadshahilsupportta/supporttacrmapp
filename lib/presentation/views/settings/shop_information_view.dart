import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/shop_card_widget.dart';

class ShopInformationView extends StatelessWidget {
  const ShopInformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Information'),
      ),
      body: Obx(() {
        if (authController.shop == null) {
          return const Center(
            child: Text('No shop data available'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ShopCardWidget(shop: authController.shop!),
        );
      }),
    );
  }
}



