import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'bindings/initial_binding.dart';
import 'theme/app_theme.dart';

class DairyFarmApp extends StatelessWidget {
  const DairyFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dairy Farm Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.main,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}