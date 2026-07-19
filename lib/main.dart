import 'package:flutter/material.dart';
import 'package:myhome/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'providers/home_provider.dart';

void main() {
  runApp(const MyHomeApp());
}

class MyHomeApp extends StatelessWidget {
  const MyHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
        ChangeNotifierProvider(
          create: (_) => HomeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'MyHome',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}