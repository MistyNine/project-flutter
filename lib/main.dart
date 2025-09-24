import 'package:flutter/material.dart';
import 'package:movie_cinema/login.dart';
import 'home_screen.dart';
import 'showtimes_screen.dart';
import 'seat_screen.dart';
import 'profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ถ้าใช้ flutterfire configure


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MovieApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Cinema',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      initialRoute: '/', // 👈 เปลี่ยนให้เริ่มต้นที่หน้า login.dart
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(), // 👈 เพิ่มเส้นทางสำหรับหน้าล็อกอิน
        '/showtimes': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ShowtimesScreen(movie: args);
        },
        '/seats': (context) => const SeatScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

