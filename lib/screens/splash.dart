import 'package:flutter/material.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:twasol/screens/login.dart';
class Splash extends StatelessWidget {
  const Splash({Key? key}) : super(key: key);
  static const id="splash_screen";
  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.scale(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.blue,
        ],
      ),
      childWidget: SizedBox(
        height: 600,
        child: Image.asset("image/Screenshot 2023-11-26 221348.png"),
      ),
      duration: const Duration(milliseconds: 1500),
      animationDuration: const Duration(milliseconds: 1000),
      onAnimationEnd: () => debugPrint("On Scale End"),
      nextScreen: const Login(),
    );
}
}
