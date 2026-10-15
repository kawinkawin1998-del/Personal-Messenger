import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const KvApp());
}

class KvApp extends StatelessWidget {
  const KvApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kawin Vinu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF111B21),
          colorScheme: const ColorScheme.dark(primary: Color(0xFF00A884)),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF202C33)),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return s.data == null ? const LoginPage() : const HomePage();
          },
        ),
      );
}
