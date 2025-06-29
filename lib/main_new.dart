import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sinais_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AgendadorApp());
}

class AgendadorApp extends StatelessWidget {
  const AgendadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SinaisProvider(),
      child: MaterialApp(
        title: 'Agendador de Sinais',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[800],
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
        locale: const Locale('pt', 'BR'),
        home: const HomeScreen(),
      ),
    );
  }
}
