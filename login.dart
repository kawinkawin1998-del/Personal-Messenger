import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool register = false, busy = false;

  void msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> go() async {
    final p = norm(phone.text);
    if (p.length != 10 || pass.text.length < 6 || (register && name.text.trim().isEmpty)) {
      msg('Enter 10-digit phone, password (6+ chars) and name (for sign up)');
      return;
    }
    setState(() => busy = true);
    try {
      final email = '$p@kv.app';
      if (register) {
        final c = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass.text);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(c.user!.uid)
            .set({'name': name.text.trim(), 'phone': p});
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass.text);
      }
    } on FirebaseAuthException catch (e) {
      msg(e.message ?? e.code);
    } catch (e) {
      msg('$e');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Kawin Vinu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              if (register)
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name')),
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number (10 digits)')),
              TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: busy ? null : go,
                  child: Text(register ? 'Sign up' : 'Log in')),
              TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(register ? 'I already have an account' : 'Create new account')),
            ],
          ),
        ),
      );
}
