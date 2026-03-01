import 'package:get/get.dart';
import '../../views/layout/main_layout.dart';
import '../routes/app_routes.dart';
import '../bindings/initial_binding.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.main,
      page: () => const MainLayout(),
      binding: InitialBinding(),
    ),
  ];
}