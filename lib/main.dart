import 'package:flutter/material.dart';
// 🇹🇭 Localization
import 'package:flutter_localizations/flutter_localizations.dart';

// 👇 เพิ่ม import นี้เพื่อใช้ Path URL (ตัด # ออก)
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:movie_cinema/login.dart';
import 'home_screen.dart';
import 'showtimes_screen.dart';
import 'seat_screen.dart';
import 'profile.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 ตั้งค่าให้ใช้ Path URL แทน Hash URL
  setUrlStrategy(PathUrlStrategy());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MovieApp());
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

      // 🇹🇭 Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('th', 'TH'),
      ],
      locale: const Locale('th', 'TH'),

      // ตรวจสถานะล็อกอิน
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) return const HomeScreen();
          return const LoginScreen();
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/showtimes': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) return const HomeScreen();
          return ShowtimesScreen(movie: args);
        },
        '/seats': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) return const HomeScreen();

          final movieTitle = args['movieTitle'] as String? ?? 'N/A';
          final cinemaName = args['cinemaName'] as String? ?? 'N/A';
          final screenType = args['screenType'] as String? ?? 'N/A';
          final selectedTime = args['selectedTime'] as String? ?? 'N/A';
          final selectedDate = args['selectedDate'] as String? ?? 'N/A';

          return SeatScreen(
            movieTitle: movieTitle,
            cinemaName: cinemaName,
            screenType: screenType,
            selectedTime: selectedTime,
            selectedDate: selectedDate,
            showtimeData: args,
          );
        },
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
