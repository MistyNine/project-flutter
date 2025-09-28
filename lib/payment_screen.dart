// lib/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatelessWidget {
  final List<String> selectedSeats;
  final double totalPrice;
  final String movieTitle;
  final String cinemaName;
  final String screenType;
  final String selectedDate;
  final String selectedTime;
  final String? posterUrl;

  const PaymentScreen({
    super.key,
    required this.selectedSeats,
    required this.totalPrice,
    required this.movieTitle,
    required this.cinemaName,
    required this.screenType,
    required this.selectedDate,
    required this.selectedTime,
    this.posterUrl,
  });

  // ทำความสะอาดโปสเตอร์ (รองรับ TMDB path)
  String? _normalizePoster(String? raw) {
    if (raw == null) return null;
    var s = raw.trim().replaceAll('"', '').replaceAll('\u200B', '');
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) {
      if (s.startsWith('/w') || s.startsWith('/original')) {
        return 'https://image.tmdb.org/t/p$s';
      }
      return 'https://image.tmdb.org/t/p/w600_and_h900_bestv2$s';
    }
    return null;
  }

  // ✅ เซฟตั๋วลง Firestore (ส่วนที่ถูกแก้ไข)
  Future<void> _saveTicket(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('กรุณาเข้าสู่ระบบก่อนทำการชำระเงิน', style: GoogleFonts.kanit())),
      );
      // 💡 สำคัญ: ถ้าไม่มี user ให้ pop(false) กลับไป SeatScreen
      Navigator.of(context).pop(false);
      return;
    }

    final poster = _normalizePoster(posterUrl);

    try {
      await FirebaseFirestore.instance.collection('tickets').add({
        'userId': user.uid,
        'movieTitle': movieTitle,
        'cinemaName': cinemaName,
        'screenType': screenType,
        'selectedDate': selectedDate, // เก็บชื่อฟิลด์แบบที่ MyTickets รองรับ
        'selectedTime': selectedTime,
        'selectedSeats': selectedSeats, // List<String>
        'totalPrice': totalPrice,
        'posterUrl': poster ?? '',
        // ⬇️ กัน createdAt เป็น null ชั่วคราว
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': Timestamp.now(),
      });

      // แจ้งสำเร็จ
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกตั๋วเรียบร้อย ✅', style: GoogleFonts.kanit())),
      );

      // ⭐️ สำคัญ: ส่งค่า true กลับไป SeatScreen
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true);
      
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.kanit())),
      );
      
      // 💡 สำคัญ: ถ้าเกิดข้อผิดพลาด ให้ pop(false) กลับไป SeatScreen
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0');

    return PopScope( // 💡 เพิ่ม PopScope เพื่อจัดการกรณีผู้ใช้กดปุ่ม Back
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // เมื่อผู้ใช้กด Back (ยกเลิกการชำระเงิน) ให้ส่ง false กลับไป
        Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('สรุปตั๋วภาพยนตร์', style: GoogleFonts.kanit()),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ข้อมูลหนัง
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PosterBox(url: _normalizePoster(posterUrl)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movieTitle,
                            style: GoogleFonts.kanit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(cinemaName,
                            style: GoogleFonts.kanit(
                                fontSize: 14, color: Colors.white70)),
                        Text(screenType,
                            style: GoogleFonts.kanit(
                                fontSize: 14, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(selectedDate,
                                style: GoogleFonts.kanit(color: Colors.white70)),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(selectedTime,
                                style: GoogleFonts.kanit(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // ที่นั่ง
              Text('ที่นั่งที่เลือก',
                  style: GoogleFonts.kanit(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                selectedSeats.isEmpty ? '-' : selectedSeats.join(', '),
                style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.orangeAccent),
              ),
              const SizedBox(height: 20),

              // ราคา
              Text('ยอดชำระรวม',
                  style: GoogleFonts.kanit(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text('฿ ${f.format(totalPrice)}',
                  style: GoogleFonts.kanit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.greenAccent)),

              const Spacer(),

              // ปุ่มชำระเงิน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveTicket(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.kanit(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('ชำระเงิน'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ===== PosterBox =====
class _PosterBox extends StatelessWidget {
  const _PosterBox({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(10);

    if (url == null || url!.isEmpty) {
      return Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: border),
        alignment: Alignment.center,
        child: const Icon(Icons.movie, color: Colors.white54),
      );
    }

    return ClipRRect(
      borderRadius: border,
      child: Image.network(
        url!,
        width: 100,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 100,
          height: 140,
          color: const Color(0xFF2A2A2A),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.white54),
        ),
      ),
    );
  }
}