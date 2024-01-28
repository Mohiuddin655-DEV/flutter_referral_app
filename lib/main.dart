import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'options/firebase_options.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            color: Theme.of(context).primaryColor,
            titleTextStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            actionsIconTheme: const IconThemeData(
              color: Colors.white,
            ),
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                Theme.of(context).primaryColor,
              ),
              textStyle: MaterialStateProperty.all(const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              )),
              foregroundColor: MaterialStateProperty.all(
                Colors.white,
              ),
            ),
          )),
      home: const HomePage(),
    );
  }
}
