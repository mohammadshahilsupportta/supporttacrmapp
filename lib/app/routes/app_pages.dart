import 'package:get/get.dart';
import 'package:supportacrm/app/bindings/category_binding.dart';
import 'app_routes.dart';
import '../bindings/initial_binding.dart';
import '../bindings/auth_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/lead_binding.dart';
import '../../presentation/views/splash/splash_view.dart';
import '../../presentation/views/login/login_view.dart';
import '../../presentation/views/register/register_view.dart';
import '../../presentation/views/home/home_view.dart';
import '../../presentation/views/leads/leads_list_view.dart';
import '../../presentation/views/leads/lead_detail_view.dart';
import '../../presentation/views/leads/lead_create_view.dart';
import '../../presentation/views/leads/lead_edit_view.dart';
import '../../presentation/views/staff/staff_list_view.dart';
import '../../presentation/views/staff/staff_create_view.dart';
import '../../presentation/views/staff/staff_detail_view.dart';
import '../../presentation/views/categories/categories_view.dart';
import '../../presentation/views/settings/settings_view.dart';
import '../../presentation/views/profile/profile_view.dart';
import '../bindings/staff_binding.dart';
import '../bindings/activity_binding.dart';

class AppPages {
  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.LEADS,
      page: () => const LeadsListView(),
      binding: LeadBinding(),
    ),
    GetPage(
      name: AppRoutes.LEAD_CREATE,
      page: () => const LeadCreateView(),
      binding: LeadBinding(),
    ),
    GetPage(
      name: AppRoutes.LEAD_DETAIL,
      page: () {
        final leadId = Get.parameters['id'] ?? '';
        return LeadDetailView(leadId: leadId);
      },
      binding: ActivityBinding(),
    ),
    GetPage(
      name: AppRoutes.LEAD_EDIT,
      page: () {
        final leadId = Get.parameters['id'] ?? '';
        return LeadEditView(leadId: leadId);
      },
      binding: LeadBinding(),
    ),
    GetPage(
      name: AppRoutes.STAFF,
      page: () => const StaffListView(),
      binding: StaffBinding(),
    ),
    GetPage(
      name: AppRoutes.STAFF_CREATE,
      page: () => const StaffCreateView(),
      binding: StaffBinding(),
    ),
    GetPage(
      name: AppRoutes.STAFF_DETAIL,
      page: () {
        final staffId = Get.parameters['id'] ?? '';
        return StaffDetailView(staffId: staffId);
      },
      binding: StaffBinding(),
    ),
    GetPage(
      name: AppRoutes.CATEGORIES,
      page: () => const CategoriesView(),
      binding: CategoryBinding(),
    ),
    GetPage(name: AppRoutes.SETTINGS, page: () => const SettingsView()),
    GetPage(name: AppRoutes.PROFILE, page: () => const ProfileView()),
    // Add more routes here as needed
  ];
}
