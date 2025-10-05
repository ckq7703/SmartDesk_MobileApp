import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // <== Thêm dòng này

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/auth.dart';
import 'package:smartdesk/core/services/notification_service.dart';

class SmartDesk extends StatelessWidget {
  const SmartDesk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: initializeServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const LoginPage();
          }
          return SplashWidget();
        },
      ),
    );
  }
}


Future<void> initializeServices() async {
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
}


class SplashWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'SDM',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Hoặc tuỳ chỉnh theo logo bạn muốn
          ),
        ),
      ),
    );
  }
}
