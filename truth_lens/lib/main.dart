import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://quqeblwavdcihkajivhf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1cWVibHdhdmRjaWhrYWppdmhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDE4NjEsImV4cCI6MjA4ODExNzg2MX0.QIK-aqTAVSZk_p8WqC8U5Vs5ubTxHIMsTPERe35ScRI',
  );

  runApp(const TruthLensApp());
}

class TruthLensApp extends StatelessWidget {
  const TruthLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Truth Lens',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFEF9F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFFF59E0B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1F2937)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

/// Decides whether to show LoginScreen or AppShell (with bottom nav)
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.onAuthStateChange,
      builder: (context, snapshot) {
        // While waiting for first auth event, check existing session
        if (!snapshot.hasData) {
          if (AuthService.isLoggedIn) {
            return const AppShell();
          }
          return const LoginScreen();
        }

        // React to auth state changes
        final session = snapshot.data!.session;
        if (session != null) {
          return const AppShell();
        }
        return const LoginScreen();
      },
    );
  }
}
