import 'package:flutter/material.dart';
import 'package:whats_app/Screen/home_screen.dart';
import 'package:whats_app/Screen/login_signup.dart';
import 'package:whats_app/Screen/message_screen.dart';
import 'package:whats_app/models/user_model.dart';

class RoutesScreen {
  static Route<dynamic> createRoutes(RouteSettings settingsRoute) {
    final arguments = settingsRoute.arguments;

    switch (settingsRoute.name) {
      case "/":
        return MaterialPageRoute(
          builder: (c) => const LoginScreen(),
        );
      case "/login":
        return MaterialPageRoute(
          builder: (c) => const LoginScreen(),
        );
      case "/home":
        return MaterialPageRoute(
          builder: (c) => const HomeScreen(),
        );
      case "/messages":
        return MaterialPageRoute(
          builder: (c) =>  MessagesScreen(arguments as UserModel),
        );
    }

    return errorPageRoute();
  }

  static Route<dynamic> errorPageRoute() {
    return MaterialPageRoute(builder: (c) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found.'),
        ),
        body: const Center(
          child: Text(
            'Page Not Found.',
            style: TextStyle(fontSize: 22),
          ),
        ),
      );
    });
  }
}
