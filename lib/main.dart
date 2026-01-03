import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'income/income_screen.dart';
import 'expense/expense_screen.dart';
import 'asset/asset_screen.dart';
import 'debt/debt_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF72140C)),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF72140C),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF72140C),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shadowColor: Colors.grey,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/income': (context) => IncomeScreen(),
        '/expense': (context) => ExpenseScreen(),
        '/asset': (context) => AssetScreen(),
        '/debt': (context) => DebtScreen(),
      },
    );
  }
}
