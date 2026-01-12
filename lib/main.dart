import 'package:chess_app/configs/config.dart';
import 'package:chess_app/screens/config.dart';
import 'package:chess_app/screens/game.dart';
import 'package:chess_app/screens/home.dart';
import 'package:chess_app/screens/rooms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chess app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 24),
          bodyLarge: TextStyle(color: Colors.black, fontSize: 30),
          bodyMedium: TextStyle(color: Colors.green, fontSize: 20)
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            foregroundColor: Colors.brown,
          ),
        )
      ),
      routerConfig: _router,
    );
  }
}
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/config',
      builder: (context, state) => const ConfigScreen(onlineMode: false),
    ),
    GoRoute(
      path: '/offline',
      builder: (context, state) {
        //final config = state.extra as OfflineConfig;
        return const GameScreen(onlineMode: false,);
      }
    ),
    GoRoute(
      path: '/online',
      builder: (context, state) => const RoomsScreen(),
      routes: [
        GoRoute(
          path: 'config',
            builder: (context, state) => const ConfigScreen(onlineMode: true)
        ),
        GoRoute(
            path: ':id',
            builder: (context, state) {
              final String? id = state.pathParameters['id'];
              return GameScreen(onlineMode: true, id: id);
            },
        ),
      ]
    ),
  ],
);