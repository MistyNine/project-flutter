import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Class Creator สำหรับเก็บข้อมูลผู้จัดทำ (รองรับ imageUrl ที่เป็น Asset Path)
class Creator {
  final String name;
  final String role;
  final String studentId;
  final String? imageUrl; // ใช้สำหรับเก็บ path ของรูปภาพ Asset

  const Creator(this.name, this.role, this.studentId, {this.imageUrl});
}

// 2. List of Creators: 
// *** แก้ไข: ลบ 'assets/' ตัวแรกออกเพื่อป้องกัน Path ซ้ำซ้อน ***
final List<Creator> creators = const [
  Creator(
    'นาย ศกรณ์ คัจฉพันธุ์', 
    'นักพัฒนาแอปพลิเคชัน', 
    'รหัสนักศึกษา: 6621601221',
    imageUrl: 'images/profile1.jpg', // แก้ไขตรงนี้
  ),
  Creator(
    'นาย ณัฐนันท์ จันทร์แจ่ม', 
    'นักออกแบบ UI/UX', 
    'รหัสนักศึกษา: 6621600844',
    imageUrl: 'images/profile3.jpg', // แก้ไขตรงนี้
  ),
  // Creator(
  //   'นาย นภดล แสงสว่าง', 
  //   'นักออกแบบ UI/UX', 
  //   'รหัสนักศึกษา: 6621600933',
  //   imageUrl: 'images/profile2.jpg', // แก้ไขตรงนี้
  // ),
  // Card สำหรับบทบาทที่สอง (ใช้รูปภาพเดิม)
  Creator(
    'นาย นภดล แสงสว่าง', 
    'นักทดสอบระบบ', 
    'รหัสนักศึกษา: 6621600933',
    imageUrl: 'images/profile2.jpg', // แก้ไขตรงนี้
  ),
];

// 3. Helper Method สำหรับสร้าง Card แสดงข้อมูลแต่ละคน
Widget _buildCreatorCard(Creator creator) {
  // สร้าง Widget ที่เป็นรูปโปรไฟล์
  final Widget profileImage = creator.imageUrl != null
      ? CircleAvatar(
          radius: 30, // ขนาดของรูปภาพ
          // ใช้ AssetImage สำหรับรูปภาพที่เก็บในโฟลเดอร์ assets
          // AssetImage จะจัดการ Path ที่ถูกต้องให้เอง
          backgroundImage: AssetImage('assets/${creator.imageUrl!}'), 
          backgroundColor: Colors.white12,
        )
      : const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white12,
          child: Icon(Icons.person, color: Colors.white70), // ไอคอนเริ่มต้น
        );

  return Card(
    color: Colors.grey[900],
    margin: const EdgeInsets.only(bottom: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Colors.white10, width: 0.5),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      // ใช้ Row เพื่อวางรูปภาพและข้อมูลในแนวนอน
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. รูปภาพโปรไฟล์
          profileImage,
          const SizedBox(width: 16), 

          // 2. ข้อมูลผู้จัดทำ (ชื่อ, บทบาท, รหัส)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creator's Name
                Text(
                  creator.name,
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Creator's Role
                Text(
                  creator.role,
                  style: GoogleFonts.kanit(
                    color: Colors.tealAccent, // Highlight the role
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(color: Colors.white12, height: 20),
                // Creator's Student ID
                Row(
                  children: [
                    const Icon(Icons.badge, color: Colors.white54, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      creator.studentId,
                      style: GoogleFonts.kanit(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'ผู้จัดทำ',
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 24, 
          ),
        ),
        centerTitle: true,
      ),
      // ใช้ ListView เพื่อทำให้เนื้อหาเลื่อนได้
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Introductory text
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
            child: Text(
              'ทีมพัฒนาแอปพลิเคชันนี้ประกอบด้วย:',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Generate a Card for each creator
          ...creators.map((creator) => _buildCreatorCard(creator)).toList(),

          // Add some padding at the bottom for spacing
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}