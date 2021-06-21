import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/moor_database.dart';
import 'screens/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider(
      // The single instance of AppDatabase
      create: (BuildContext context) => AppDatabase().taskDao,

      child: MaterialApp(
        title: 'Material App',
        home: HomePage(),
      ),
    );
  }
}
