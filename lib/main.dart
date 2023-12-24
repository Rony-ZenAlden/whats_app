import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whats_app/Colors/default_color.dart';
import 'package:whats_app/provider/provider_chat.dart';
import 'package:whats_app/routes_screen.dart';

String firstRoute = "/";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  User? currentFirebaseUser = FirebaseAuth.instance.currentUser;
  if (currentFirebaseUser != null) {
    firstRoute = '/login';
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ProviderChat(),
      child: const MyApp(),
    ),
  );
}

final ThemeData defaultThemeOfApp = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: DefaultColors.primaryColor),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whats-app Web App',
      theme: defaultThemeOfApp,
      initialRoute: firstRoute,
      onGenerateRoute: RoutesScreen.createRoutes,
      // home: const LoginScreen(),
    );
  }
}