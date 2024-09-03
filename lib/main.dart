import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:user_app/appInfo/app_info.dart';
import 'package:user_app/authentication/login_screen.dart';
import 'package:user_app/authentication/otp_screen.dart';
import 'package:user_app/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyA7mgbNTPGT1cBbhTqmlsIWzB2Y1R219YQ",
          authDomain: "taxis-f13a0.firebaseapp.com",
          projectId: "taxis-f13a0",
          storageBucket: "taxis-f13a0.appspot.com",
          messagingSenderId: "448021053069",
          appId: "1:448021053069:web:14b8e1e42df5d276476cc4",
          measurementId: "G-3DDX3Z87FE"));

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Flutter User App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        home: FirebaseAuth.instance.currentUser == null
            ? const LoginScreen()
            : const HomePage(),
      ),
    );
  }
}
