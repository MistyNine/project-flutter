import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import services and models
import 'authentication.dart';
import 'usermodel.dart';

// ✅ import หน้าใหม่
import 'my_tickets_screen.dart';
import 'login.dart'; 

// 🎯 สมมติว่านี่คือหน้าจอใหม่ที่คุณจะสร้าง
import 'about_us_screen.dart'; 
// (คุณต้องสร้างไฟล์ about_us_screen.dart ด้วยตัวเอง)

class ProfileScreen extends StatelessWidget {
  final QueryDocumentSnapshot? doc;

  const ProfileScreen({super.key, this.doc});

  Future<void> userprofile(UserModel user) async {
    final docRef = FirebaseFirestore.instance.collection("users").doc(user.id);

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data();
      print("Document data: $data");
    } else {
      print("No such document!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4.0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'โปรไฟล์',
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ส่วนหัวโปรไฟล์
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28, 
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ผู้ใช้ใหม่',
                        style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    Text(AuthenticationService().getEmail() ?? 'ไม่เจอผู้ใช้',
                        style: GoogleFonts.kanit(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ปุ่มตั๋วของฉัน
          _Tile(
            icon: Icons.confirmation_number_outlined,
            title: 'ตั๋วของฉัน',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
              );
            },
          ),

          // ✅ แก้ไขเป็น 'ผู้จัดทำ' และนำทางไปหน้า AboutUsScreen
          _Tile(
            icon: Icons.info_outline, // เปลี่ยนไอคอนให้เหมาะสมยิ่งขึ้น
            title: 'ผู้จัดทำ',
            onTap: () {
              // 🎯 นำทางไปยังหน้าจอที่คุณต้องการ (AboutUsScreen)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsScreen()),
              );
              // โค้ดเดิม (userprofile) ถูกเอาออกไปแล้ว
            },
          ),

          const SizedBox(height: 12),

          _Tile(
            icon: Icons.logout,
            title: 'ออกจากระบบ',
            danger: true,
            onTap: () {
              AuthenticationService().logout();
              // โค้ดที่ทำให้ไปหน้า LoginScreen และล้าง History ทั้งหมด
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        leading: Icon(icon, color: danger ? Colors.redAccent : Colors.white70),
        title: Text(
          title,
          style: GoogleFonts.kanit(
            color: danger ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}