import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'widgets/login_form_widget.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure AuthController is registered (from AuthBinding)
    // If not registered, create it
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }

    final authController = Get.find<AuthController>();

    return Scaffold(body: LoginFormWidget(controller: authController));
  }
}
