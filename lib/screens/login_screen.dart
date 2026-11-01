import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(); final password = TextEditingController();
  bool busy = false; String? error;
  Future<void> run(Future<void> Function() action) async {
    setState(() {busy = true; error = null;});
    try { await action(); } catch (_) { if (mounted) setState(() => error = 'تعذر تسجيل الدخول. تحقق من الحساب والاتصال.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.storefront, size: 70, color: Color(0xFF17314D)),
    const SizedBox(height: 12), const Text('SALEH STORE PRO', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    const SizedBox(height: 30), TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
    const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
    const SizedBox(height: 12), FilledButton(onPressed: busy ? null : () => run(() async { await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text); }), child: const Text('دخول العامل')),
    const SizedBox(height: 12), OutlinedButton.icon(icon: const Icon(Icons.account_circle), label: const Text('دخول المدير بواسطة Google'), onPressed: busy ? null : () => run(() async {
      final account = await GoogleSignIn().signIn(); if (account == null) return;
      final auth = await account.authentication;
      await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken));
    })),
    if (busy) const CircularProgressIndicator(), if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
  ])))));
}
