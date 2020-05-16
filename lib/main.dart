import 'package:app/fonts.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/login_page/landing_page.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickGrab',
      theme: ThemeData(
        primaryColor: Color.fromRGBO(250, 100, 0, 1),
        accentColor: Color.fromRGBO(250, 100, 0, 1),
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: AppFontFamilies.mainFont,
      ),
      home: LandingPage(title: 'Flutter Demo Home Page'),
      routes: <String, WidgetBuilder>{
        "/home": (_) => LandingPage(title: 'Landing Page')
      },
    );
  }
}

