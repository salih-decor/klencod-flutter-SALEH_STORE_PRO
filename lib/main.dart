import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SalehApp());
}

class SalehApp extends StatelessWidget {
  const SalehApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SALEH STORE PRO', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF17314D)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7FA)),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return snapshot.data == null ? const LoginScreen() : const HomeScreen();
    }),
  );
}