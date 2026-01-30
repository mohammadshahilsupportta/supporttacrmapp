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
import '../../presentation/views/settings/shop_information_view.dart';
import '../../presentation/views/settings/help_support_view.dart';
import '../../presentation/views/profile/profile_view.dart';
import '../../presentation/views/reports/reports_view.dart';
import '../bindings/staff_binding.dart';
import '../bindings/activity_binding.dart';
import '../bindings/report_binding.dart';
import '../bindings/leaderboard_binding.dart';
import '../../presentation/views/leaderboard/leaderboard_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.leads,
      page: () => const LeadsListView(),
      binding: LeadBinding(),
    ),
    GetPage(
      name: AppRoutes.leadCreate,
      page: () => const LeadCreateView(),
      binding: LeadBinding(),
    ),
    GetPage(
      name: AppRoutes.leadDetail,
      page: () {
        final leadId = Get.parameters['id'] ?? '';
        return LeadDetailView(leadId: leadId);
      },
      binding: ActivityBinding(),
    ),
    GetPage(
      name: AppRoutes.leadEdit,
      page: () {
        final leadId = Get.parameters['id'] ?? '';
        return LeadEditView(leadId: leadId);
      },
      binding: LeadBinding(),
    ),
    GetPage(
      name: AppRoutes.staff,
      page: () => const StaffListView(),
      binding: StaffBinding(),
    ),
    GetPage(
      name: AppRoutes.staffCreate,
      page: () => const StaffCreateView(),
      binding: StaffBinding(),
    ),
    GetPage(
      name: AppRoutes.staffDetail,
      page: () {
        final staffId = Get.parameters['id'] ?? '';
        return StaffDetailView(staffId: staffId);
      },
      binding: StaffBinding(),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesView(),
      binding: CategoryBinding(),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileView()),
    GetPage(
      name: AppRoutes.shopInformation,
      page: () => const ShopInformationView(),
    ),
    GetPage(name: AppRoutes.helpSupport, page: () => const HelpSupportView()),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsView(),
      binding: ReportBinding(),
    ),
    GetPage(
      name: AppRoutes.leaderboard,
      page: () => const LeaderboardView(),
      binding: LeaderboardBinding(),
    ),
    // Add more routes here as needed
  ];
}
