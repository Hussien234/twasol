import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:twasol/screens/ForgotPassword.dart';
import 'package:twasol/screens/chat.dart';
import 'package:twasol/screens/home.dart';
import 'package:twasol/screens/login.dart';
import 'package:twasol/screens/signup.dart';
import 'package:twasol/screens/splash.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void>main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await configureLocalNotifications();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(TwasolApp(savedThemeMode: savedThemeMode));
}
Future<void> configureLocalNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final InitializationSettings initializationSettings =
  InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class TwasolApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const TwasolApp({Key? key, this.savedThemeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Fluttertoast.showToast(msg: 'App initialized');
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        theme: theme,
        darkTheme: darkTheme,
        initialRoute: Splash.id,
        routes: {
          Splash.id: (context) => Splash(),
          Login.id: (context) => Login(),
          Home.id: (context) => Home(),
          Signup.id:(context) => Signup(),
          ForgotPassword.id:(context)=>ForgotPassword(),

        },
      ),
    );
  }
}

