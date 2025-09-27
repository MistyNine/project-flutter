import 'package:flutter/material.dart';
// 🇹🇭 เพิ่ม import สำหรับ Localization 🇹🇭
import 'package:flutter_localizations/flutter_localizations.dart'; 

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

      // =====================================
      // 🇹🇭 ตั้งค่า Localization (Locale) สำหรับภาษาไทย 🇹🇭
      // =====================================
      localizationsDelegates: const [
        // Delegates ที่จำเป็นสำหรับ Material/Widgets/Cupertino
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // กำหนด Locale ที่แอปฯ รองรับ
      supportedLocales: const [
        Locale('en', 'US'), // ภาษาอังกฤษ
        Locale('th', 'TH'), // ภาษาไทย
      ],

      // กำหนด Locale เริ่มต้นเป็นภาษาไทย (เพื่อให้ ShowtimesScreen ทำงานได้ทันที)
      locale: const Locale('th', 'TH'), 
      
      // =====================================

      // แก้ไขตรงนี้เพื่อตรวจสอบสถานะการล็อกอิน
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // หากมีข้อมูลผู้ใช้ (ล็อกอินอยู่) ไปที่ HomeScreen
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // หากไม่มีข้อมูลผู้ใช้ (ยังไม่ล็อกอิน) ไปที่ LoginScreen
          return const LoginScreen();
        },
      ),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/showtimes': (context) {
          // 💡 ตรวจสอบว่า args ไม่เป็น null ก่อนส่ง
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            // กรณีไม่มี argument ส่งมา อาจจะกลับไปหน้าหลักหรือแสดง Error
            return const HomeScreen(); 
          }
          return ShowtimesScreen(movie: args);
        },
        // ✅ แก้ไข: Route /seats ที่ถูกทำความสะอาดจาก Illegal Character แล้ว
        '/seats': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            // กรณีไม่มี argument ส่งมา
            return const HomeScreen(); 
          }

          // ดึงค่าที่จำเป็นทั้งหมดออกมาจาก Map args อย่างปลอดภัย 
          // ใช้ as String? ?? 'N/A' เพื่อกำหนดค่า Default ในกรณีที่ค่าเป็น null หรือ key หายไป
          final movieTitle = args['movieTitle'] as String? ?? 'N/A';
          final cinemaName = args['cinemaName'] as String? ?? 'N/A';
          final screenType = args['screenType'] as String? ?? 'N/A';
          final selectedTime = args['selectedTime'] as String? ?? 'N/A';
          final selectedDate = args['selectedDate'] as String? ?? 'N/A';
          
          // ส่ง argument ที่จำเป็นทั้งหมดไปยัง SeatScreen
          return SeatScreen(
            movieTitle: movieTitle,
            cinemaName: cinemaName,
            screenType: screenType,
            selectedTime: selectedTime,
            selectedDate: selectedDate,
            showtimeData: args, // showtimeData คือ args ทั้งก้อน
          );
        },
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
