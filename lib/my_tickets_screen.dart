// lib/my_tickets_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('ตั๋วของฉัน', style: GoogleFonts.kanit()),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? Center(
              child: Text('กรุณาเข้าสู่ระบบก่อน',
                  style: GoogleFonts.kanit(color: Colors.white70)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tickets')
                  .where('userId', isEqualTo: user.uid)
                  // ใช้เวลาจากเครื่องเพื่อกัน createdAt (serverTimestamp) เป็น null ชั่วคราว
                  .orderBy('createdAtClient', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // ✅ แสดงสาเหตุถ้ามี error (เช่นต้องสร้าง Index หรือสิทธิ์ไม่พอ)
                if (snapshot.hasError) {
                  final msg = snapshot.error.toString();
                  // ignore: avoid_print
                  print('[MyTickets] Firestore error => $msg');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'เกิดข้อผิดพลาด:\n$msg',
                        textAlign: TextAlign.center,
                        style:
                            GoogleFonts.kanit(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('คุณยังไม่มีตั๋ว',
                        style: GoogleFonts.kanit(color: Colors.white70)),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i) {
                    final t = docs[i].data() as Map<String, dynamic>;

                    final poster = (t['posterUrl'] as String?) ?? '';
                    final movieTitle = (t['movieTitle'] as String?) ?? '-';
                    final cinemaName = (t['cinemaName'] as String?) ?? '';
                    final screenType = (t['screenType'] as String?) ?? '';
                    final date =
                        (t['selectedDate'] ?? t['date']) as String? ?? '';
                    final time =
                        (t['selectedTime'] ?? t['time']) as String? ?? '';
                    final seats = (t['selectedSeats'] ?? t['seats'])
                            as List<dynamic>? ??
                        const [];
                    final total = t['totalPrice'];

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: _PosterThumb(url: poster),
                        title: Text(
                          movieTitle,
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$cinemaName | $screenType\n'
                            'วันที่ $date เวลา $time\n'
                            'ที่นั่ง: ${seats.join(', ')}\n'
                            'รวม: ฿$total',
                            style: GoogleFonts.kanit(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PosterThumb extends StatelessWidget {
  const _PosterThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Icon(Icons.movie, color: Colors.white54, size: 48);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 50,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white54, size: 48),
      ),
    );
  }
}
